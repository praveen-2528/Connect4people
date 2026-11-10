import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/booking_model.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import 'become_companion_screen.dart';

class CompanionDashboardScreen extends ConsumerStatefulWidget {
  const CompanionDashboardScreen({super.key});

  @override
  ConsumerState<CompanionDashboardScreen> createState() => _CompanionDashboardScreenState();
}

class _CompanionDashboardScreenState extends ConsumerState<CompanionDashboardScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(bookingProvider.notifier).fetchBookings();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final profile = user?.companionProfile;
    final bookings = ref.watch(bookingProvider).companionBookings;

    // Calculate metrics
    final completedBookings = bookings.where((b) => b.status == 'completed').toList();
    final totalEarnings = completedBookings.fold<double>(0.0, (sum, b) => sum + b.companionPayout);
    final pendingRequests = bookings.where((b) => b.status == 'pending').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Companion Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Rates',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BecomeCompanionScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earnings Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Net Earnings (80% Payout)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      '₹${totalEarnings.round()}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricCol('Completed Meetups', '${completedBookings.length}'),
                        _buildMetricCol('Rating', '⭐ ${profile?.avgRating.toStringAsFixed(1) ?? '5.0'}'),
                        _buildMetricCol('Current Rate', '₹${profile?.hourlyRate.round() ?? 500}/hr'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pending Incoming Requests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Incoming Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pendingRequests.isNotEmpty ? AppColors.warning.withOpacity(0.15) : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pendingRequests.length} pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: pendingRequests.isNotEmpty ? AppColors.warning : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (pendingRequests.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.inbox_rounded, size: 44, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text('No pending requests', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                ...pendingRequests.map((b) => _buildIncomingRequestCard(b)),

              const SizedBox(height: 24),

              // Action shortcut to edit rates
              Card(
                child: ListTile(
                  leading: const Icon(Icons.tune_rounded, color: AppColors.primary),
                  title: const Text('Update Rates & Availability', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Adjust your hourly/event rates anytime'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BecomeCompanionScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildIncomingRequestCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    booking.otherPartyName.isNotEmpty ? booking.otherPartyName[0] : 'C',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.otherPartyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        'Total: ₹${booking.amount.round()} (You get ₹${booking.companionPayout.round()})',
                        style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Location: ${booking.location ?? 'Public place'}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(bookingProvider.notifier).declineBooking(booking.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref.read(bookingProvider.notifier).acceptBooking(booking.id),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
