import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/constants.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';

class BookingPaymentScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingPaymentScreen({super.key, required this.booking});

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  final ApiService _api = ApiService();
  final _refNoteController = TextEditingController();

  String _upiId = 'connect4people@upi';
  String _qrUrl = '';
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchPaymentInfo();
  }

  @override
  void dispose() {
    _refNoteController.dispose();
    super.dispose();
  }

  Future<void> _fetchPaymentInfo() async {
    final res = await _api.getBookingPaymentInfo(widget.booking.id);
    if (res.success && res.data != null) {
      setState(() {
        _upiId = res.data['upi_id']?.toString() ?? 'connect4people@upi';
        _qrUrl = res.data['qr_url']?.toString() ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _claimPayment() async {
    final note = _refNoteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter UPI Transaction / UTR reference')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await _api.claimBookingPayment(
      widget.booking.id,
      method: 'UPI',
      referenceNote: note,
    );

    setState(() => _isSubmitting = false);

    if (res.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking payment submitted! Awaiting companion/admin confirmation.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pay for Booking'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹${widget.booking.amount.round()}',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Payment for meetup with ${widget.booking.otherPartyName}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // QR Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_qrUrl.isNotEmpty)
                            Image.network(
                              _qrUrl,
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildQrFallback(),
                            )
                          else
                            _buildQrFallback(),
                          const SizedBox(height: 14),
                          const Text(
                            'Scan with Any UPI App',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_upiId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _upiId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('UPI ID copied!')),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text('UPI UTR / Reference ID', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _refNoteController,
                      decoration: const InputDecoration(
                        hintText: 'Enter 12-digit UTR from GPay / PhonePe / Paytm',
                        prefixIcon: Icon(Icons.receipt_long_rounded, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _claimPayment,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('I Have Paid ₹${widget.booking.amount.round()}'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQrFallback() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 90, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(_upiId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
