import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/companion_model.dart';
import '../providers/companion_provider.dart';
import 'companion_detail_screen.dart';
import 'filter_bottom_sheet.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialFilter: ref.read(companionProvider).filter,
        onApply: (newFilter) {
          ref.read(companionProvider.notifier).updateFilter(newFilter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companionProvider);
    final companions = state.filteredCompanions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Companions'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune_rounded),
                if (state.filter.gender != null || state.filter.city != null || state.filter.minRating != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
              ],
            ),
            tooltip: 'Filter',
            onPressed: _openFilter,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(companionProvider.notifier).setSearchQuery(val);
                },
                decoration: InputDecoration(
                  hintText: 'Search by name, city, or interests...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(companionProvider.notifier).setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Active Filter Chips
            if (state.filter.gender != null || state.filter.city != null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    if (state.filter.gender != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(state.filter.gender!),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          onDeleted: () {
                            ref.read(companionProvider.notifier).updateFilter(
                                  state.filter.copyWith(clearGender: true),
                                );
                          },
                        ),
                      ),
                    if (state.filter.city != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(state.filter.city!),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          onDeleted: () {
                            ref.read(companionProvider.notifier).updateFilter(
                                  state.filter.copyWith(clearCity: true),
                                );
                          },
                        ),
                      ),
                  ],
                ),
              ),

            // Companion List
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : companions.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => ref.read(companionProvider.notifier).fetchCompanions(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: companions.length,
                            itemBuilder: (context, index) {
                              final comp = companions[index];
                              return _buildCompanionCard(comp);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanionCard(CompanionCardModel comp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CompanionDetailScreen(companion: comp),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image / Avatar Header
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  comp.photos.isNotEmpty
                      ? Image.network(
                          comp.photos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildCardAvatarFallback(),
                        )
                      : _buildCardAvatarFallback(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              comp.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 18),
                          ],
                        ),
                        if (comp.city != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(comp.city!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            comp.avgRating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (comp.tagline != null && comp.tagline!.isNotEmpty)
                    Text(
                      comp.tagline!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 8),

                  // Interests Preview
                  if (comp.interests.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: comp.interests.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),

                  // Pricing & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rate', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '₹${comp.hourlyRate.round()}/hr',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(110, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CompanionDetailScreen(companion: comp),
                            ),
                          );
                        },
                        child: const Text('View Profile', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAvatarFallback() {
    return Container(
      color: const Color(0xFFF3E5F5),
      child: const Center(
        child: Icon(Icons.person, size: 72, color: Color(0xFFBA68C8)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline_rounded, size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'No companions found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search query or filters',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              ref.read(companionProvider.notifier).updateFilter(CompanionFilter());
              _searchController.clear();
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
}
