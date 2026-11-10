import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../providers/companion_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  final CompanionFilter initialFilter;
  final Function(CompanionFilter) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _gender;
  late String? _city;
  late RangeValues _priceRange;
  late double _minRating;

  final List<String> _cities = ['All', 'Mumbai', 'Delhi NCR', 'Bengaluru', 'Hyderabad', 'Pune', 'Kolkata', 'Chennai'];
  final List<String> _genders = ['All', 'Female', 'Male', 'Non-Binary'];

  @override
  void initState() {
    super.initState();
    _gender = widget.initialFilter.gender ?? 'All';
    _city = widget.initialFilter.city ?? 'All';
    _priceRange = RangeValues(
      widget.initialFilter.minPrice ?? 300,
      widget.initialFilter.maxPrice ?? 5000,
    );
    _minRating = widget.initialFilter.minRating ?? 3.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Companions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gender
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _genders.map((g) {
              final selected = _gender == g;
              return ChoiceChip(
                label: Text(g),
                selected: selected,
                selectedColor: AppColors.primary.withOpacity(0.18),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) setState(() => _gender = g);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // City
          const Text('City', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _cities.map((c) {
              final selected = _city == c;
              return ChoiceChip(
                label: Text(c),
                selected: selected,
                selectedColor: AppColors.primary.withOpacity(0.18),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) setState(() => _city = c);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Price Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hourly Rate (₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('₹${_priceRange.start.round()} - ₹${_priceRange.end.round()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 100,
            max: 10000,
            divisions: 99,
            activeColor: AppColors.primary,
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          const SizedBox(height: 16),

          // Minimum Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  Text(' ${_minRating.toStringAsFixed(1)}+', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Slider(
            value: _minRating,
            min: 1.0,
            max: 5.0,
            divisions: 8,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _minRating = v),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(CompanionFilter());
                    Navigator.pop(context);
                  },
                  child: const Text('Reset All'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final filter = CompanionFilter(
                      gender: _gender == 'All' ? null : _gender,
                      city: _city == 'All' ? null : _city,
                      minPrice: _priceRange.start,
                      maxPrice: _priceRange.end,
                      minRating: _minRating,
                    );
                    widget.onApply(filter);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filter'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
