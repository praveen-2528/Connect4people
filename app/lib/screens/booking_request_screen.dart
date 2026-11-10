import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/companion_model.dart';
import '../providers/booking_provider.dart';
import 'booking_detail_screen.dart';

class BookingRequestScreen extends ConsumerStatefulWidget {
  final CompanionCardModel companion;

  const BookingRequestScreen({super.key, required this.companion});

  @override
  ConsumerState<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends ConsumerState<BookingRequestScreen> {
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String _bookingType = 'hourly'; // 'hourly' or 'event'
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  int _durationHours = 2;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _baseAmount {
    if (_bookingType == 'event') {
      return widget.companion.eventRate;
    }
    return widget.companion.hourlyRate * _durationHours;
  }

  double get _platformFee => _baseAmount * 0.20; // 20% platform commission
  double get _companionPayout => _baseAmount * 0.80; // 80% to companion

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleSubmit() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a public meeting location (e.g. Café Coffee Day)')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final endDateTime = _bookingType == 'event'
        ? startDateTime.add(const Duration(hours: 6))
        : startDateTime.add(Duration(hours: _durationHours));

    final booking = await ref.read(bookingProvider.notifier).createBooking(
      companionId: widget.companion.userId,
      bookingType: _bookingType,
      startTime: startDateTime,
      endTime: endDateTime,
      location: location,
      notes: _notesController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (booking != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request sent successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(booking: booking),
        ),
      );
    } else if (mounted) {
      final err = ref.read(bookingProvider).errorMessage ?? 'Failed to send booking request';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(_selectedDate);
    final timeStr = _selectedTime.format(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Book ${widget.companion.name}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Companion preview card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        widget.companion.name.isNotEmpty ? widget.companion.name[0] : 'C',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.companion.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '₹${widget.companion.hourlyRate.round()}/hr • ₹${widget.companion.eventRate.round()}/event',
                            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Booking Type
              const Text('Booking Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          'Hourly (₹${widget.companion.hourlyRate.round()}/hr)',
                          style: TextStyle(
                            fontWeight: _bookingType == 'hourly' ? FontWeight.bold : FontWeight.normal,
                            color: _bookingType == 'hourly' ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      selected: _bookingType == 'hourly',
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      onSelected: (val) {
                        if (val) setState(() => _bookingType = 'hourly');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          'Full Event (₹${widget.companion.eventRate.round()})',
                          style: TextStyle(
                            fontWeight: _bookingType == 'event' ? FontWeight.bold : FontWeight.normal,
                            color: _bookingType == 'event' ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      selected: _bookingType == 'event',
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      onSelected: (val) {
                        if (val) setState(() => _bookingType = 'event');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date & Time pickers
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(dateStr, style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(timeStr, style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Duration selector (if hourly)
              if (_bookingType == 'hourly') ...[
                const Text('Duration (Hours)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [1, 2, 3, 4, 6].map((hrs) {
                    final isSel = _durationHours == hrs;
                    return ChoiceChip(
                      label: Text('$hrs hr${hrs > 1 ? 's' : ''}'),
                      selected: isSel,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? AppColors.primary : AppColors.textPrimary,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _durationHours = hrs);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Meeting Location
              const Text('Public Meeting Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Starbucks Bandra, High Street Phoenix Mall',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),

              // Occasion / Notes
              const Text('Occasion & Special Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Friend\'s birthday dinner, dress code is semi-formal...',
                ),
              ),
              const SizedBox(height: 28),

              // Cost Breakdown Card (with 20% platform fee transparency)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _bookingType == 'hourly'
                              ? 'Base Fee (${_durationHours} hrs × ₹${widget.companion.hourlyRate.round()})'
                              : 'Event Base Fee',
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        Text('₹${_baseAmount.round()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Platform Commission (20%)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text('₹${_platformFee.round()}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Companion Share (80%)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text('₹${_companionPayout.round()}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: Color(0xFFE0E0E0)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount Payable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '₹${_baseAmount.round()}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Request Booking • ₹${_baseAmount.round()}'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
