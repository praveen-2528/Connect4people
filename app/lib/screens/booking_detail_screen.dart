import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/booking_model.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
import 'booking_payment_screen.dart';
import 'chat_screen.dart';
import 'review_dialog.dart';
import 'report_dialog.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  late BookingModel _booking;
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.secondary;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'declined':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  Future<void> _handleAccept() async {
    setState(() => _isLoadingAction = true);
    final ok = await ref.read(bookingProvider.notifier).acceptBooking(_booking.id);
    setState(() => _isLoadingAction = false);
    if (ok) {
      _refreshDetails();
    }
  }

  Future<void> _handleDecline() async {
    setState(() => _isLoadingAction = true);
    final ok = await ref.read(bookingProvider.notifier).declineBooking(_booking.id);
    setState(() => _isLoadingAction = false);
    if (ok) {
      _refreshDetails();
    }
  }

  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoadingAction = true);
      final ok = await ref.read(bookingProvider.notifier).cancelBooking(_booking.id);
      setState(() => _isLoadingAction = false);
      if (ok) {
        _refreshDetails();
      }
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoadingAction = true);
    final ok = await ref.read(bookingProvider.notifier).completeBooking(_booking.id);
    setState(() => _isLoadingAction = false);
    if (ok) {
      _refreshDetails();
    }
  }

  Future<void> _openChat() async {
    final currentUserId = ref.read(authProvider).user?.id;
    final otherUserId = _booking.clientId == currentUserId ? _booking.companionId : _booking.clientId;

    // Get or create conversation
    final res = await ApiService().createConversation(otherUserId, bookingId: _booking.id);
    if (res.success && res.data != null && mounted) {
      final convId = res.data['id'];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            otherUserName: _booking.otherPartyName,
            otherUserId: otherUserId,
          ),
        ),
      );
    }
  }

  Future<void> _refreshDetails() async {
    final res = await ApiService().getBookingDetail(_booking.id);
    if (res.success && res.data != null && mounted) {
      setState(() {
        _booking = BookingModel.fromJson(res.data);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).user?.id;
    final isCompanion = _booking.companionId == currentUserId;
    final isClient = _booking.clientId == currentUserId;

    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_booking.startTime);
    final timeStr =
        '${DateFormat('hh:mm a').format(_booking.startTime)} - ${DateFormat('hh:mm a').format(_booking.endTime)}';

    final statusColor = _getStatusColor(_booking.status);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Report',
            onPressed: () {
              final otherUserId = isCompanion ? _booking.clientId : _booking.companionId;
              showDialog(
                context: context,
                builder: (_) => ReportDialog(reportedUserId: otherUserId, bookingId: _booking.id),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: statusColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${_booking.status.toUpperCase()}',
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            _getStatusDescription(_booking.status, isCompanion),
                            style: TextStyle(color: statusColor.withOpacity(0.9), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Other Party Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        _booking.otherPartyName.isNotEmpty ? _booking.otherPartyName[0] : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _booking.otherPartyName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          Text(
                            isCompanion ? 'Client' : 'Companion',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (_booking.status == 'accepted' || _booking.status == 'ongoing')
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
                        tooltip: 'Open Chat',
                        onPressed: _openChat,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Meeting Details
              const Text('Meeting Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.calendar_month_rounded, 'Date', dateStr),
              _buildDetailRow(Icons.access_time_rounded, 'Time', timeStr),
              _buildDetailRow(Icons.place_rounded, 'Location', _booking.location ?? 'Public Location'),
              _buildDetailRow(Icons.category_rounded, 'Booking Type', _booking.bookingType.toUpperCase()),
              if (_booking.notes != null && _booking.notes!.isNotEmpty)
                _buildDetailRow(Icons.notes_rounded, 'Occasion / Notes', _booking.notes!),
              const SizedBox(height: 24),

              // Payment & Rates
              const Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Booking Amount', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        Text('₹${_booking.amount.round()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Platform Fee (20%)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text('₹${_booking.platformFee.round()}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Companion Payout (80%)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text('₹${_booking.companionPayout.round()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons Based on Role & Status
              if (_isLoadingAction)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Companion pending actions: Accept / Decline
                if (isCompanion && _booking.status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleDecline,
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleAccept,
                          child: const Text('Accept Booking'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Client accepted action: Pay Booking
                if (isClient && _booking.status == 'accepted') ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: Text('Pay Booking Fee • ₹${_booking.amount.round()}'),
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => BookingPaymentScreen(booking: _booking),
                        ),
                      );
                      if (updated == true) _refreshDetails();
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Chat action (if accepted or ongoing)
                if (_booking.status == 'accepted' || _booking.status == 'ongoing') ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text('Chat with ${_booking.otherPartyName}'),
                    onPressed: _openChat,
                  ),
                  const SizedBox(height: 14),
                ],

                // Complete Meetup (either companion or client when accepted)
                if (_booking.status == 'accepted' || _booking.status == 'ongoing') ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Mark Meetup as Completed'),
                    onPressed: _handleComplete,
                  ),
                  const SizedBox(height: 14),
                ],

                // Review button (if completed)
                if (_booking.status == 'completed') ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.star_outline_rounded),
                    label: const Text('Leave a Review & Rating'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ReviewDialog(
                          bookingId: _booking.id,
                          companionName: _booking.otherPartyName,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Cancel booking (if pending or accepted)
                if (_booking.status == 'pending' || _booking.status == 'accepted') ...[
                  Center(
                    child: TextButton(
                      onPressed: _handleCancel,
                      child: const Text('Cancel Booking Request', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(String status, bool isCompanion) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return isCompanion ? 'You accepted this booking.' : 'Companion accepted! Pay and coordinate meetup.';
      case 'ongoing':
        return 'Meetup is currently ongoing.';
      case 'completed':
        return 'Meetup completed successfully.';
      case 'cancelled':
        return 'This booking was cancelled.';
      case 'declined':
        return 'Booking request was declined.';
      case 'pending':
      default:
        return isCompanion ? 'Review and accept or decline.' : 'Waiting for companion to accept.';
    }
  }
}
