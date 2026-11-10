import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/api_service.dart';

class ReportDialog extends StatefulWidget {
  final String reportedUserId;
  final String? bookingId;

  const ReportDialog({
    super.key,
    required this.reportedUserId,
    this.bookingId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ApiService _api = ApiService();
  final _descController = TextEditingController();

  String _reason = 'Inappropriate behavior';
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Inappropriate behavior',
    'Safety or boundary violation',
    'No show / Late arrival',
    'Harassment or verbal abuse',
    'Fake profile / Misrepresentation',
    'Payment issue',
    'Other'
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);

    final res = await _api.reportUser(
      reportedUserId: widget.reportedUserId,
      bookingId: widget.bookingId,
      reason: _reason,
      description: _descController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (res.success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Our safety team will review this promptly.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.report_problem_rounded, color: AppColors.error),
          SizedBox(width: 8),
          Text('Report User'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your safety is our top priority. Reports are strictly confidential and investigated by our moderation team.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 16),
            const Text('Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _reason,
              isExpanded: true,
              items: _reasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _reason = val);
              },
            ),
            const SizedBox(height: 16),
            const Text('Details / Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Please provide as much context as possible...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            minimumSize: const Size(100, 44),
          ),
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}
