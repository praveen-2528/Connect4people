import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'pending_activation_screen.dart';

class RegistrationPaymentScreen extends ConsumerStatefulWidget {
  const RegistrationPaymentScreen({super.key});

  @override
  ConsumerState<RegistrationPaymentScreen> createState() => _RegistrationPaymentScreenState();
}

class _RegistrationPaymentScreenState extends ConsumerState<RegistrationPaymentScreen> {
  final ApiService _api = ApiService();
  final _refNoteController = TextEditingController();

  String _fee = '299';
  String _upiId = 'connect4people@upi';
  String _qrUrl = '';
  bool _isLoadingInfo = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadRegistrationInfo();
  }

  @override
  void dispose() {
    _refNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrationInfo() async {
    final res = await _api.getRegistrationInfo();
    if (res.success && res.data != null) {
      setState(() {
        _fee = res.data['fee']?.toString() ?? '299';
        _upiId = res.data['upi_id']?.toString() ?? 'connect4people@upi';
        _qrUrl = res.data['qr_url']?.toString() ?? '';
        _isLoadingInfo = false;
      });
    } else {
      setState(() => _isLoadingInfo = false);
    }
  }

  Future<void> _handleClaimPayment() async {
    final note = _refNoteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter UPI Transaction ID / UTR number')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await _api.claimRegistrationPayment(
      method: 'UPI',
      referenceNote: note,
    );

    setState(() => _isSubmitting = false);

    if (res.success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PendingActivationScreen()),
      );
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
        title: const Text('One-Time Registration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          )
        ],
      ),
      body: SafeArea(
        child: _isLoadingInfo
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_outlined, color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'One-Time Member Fee',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '₹$_fee',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Lifetime access to Connect4People',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 28),

                    // QR Code Container
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
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildQrPlaceholder(),
                            )
                          else
                            _buildQrPlaceholder(),
                          const SizedBox(height: 16),
                          const Text(
                            'Scan with Any UPI App',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Google Pay, PhonePe, Paytm, BHIM, etc.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          // UPI ID with Copy
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _upiId,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _upiId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('UPI ID copied to clipboard!')),
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
                    const SizedBox(height: 28),

                    // Step instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('How it works:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 8),
                          Text('1. Pay ₹299 using the QR code or UPI ID above.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          SizedBox(height: 4),
                          Text('2. Note your 12-digit UPI UTR / Transaction ID.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          SizedBox(height: 4),
                          Text('3. Enter the UTR below and tap "I Have Paid".', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reference Note Input
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'UPI Reference ID / UTR Number',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _refNoteController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 423456789012 or your UPI reference',
                        prefixIcon: Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleClaimPayment,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('I Have Paid ₹299'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQrPlaceholder() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 100, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              _upiId,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
