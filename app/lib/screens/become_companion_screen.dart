import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class BecomeCompanionScreen extends ConsumerStatefulWidget {
  const BecomeCompanionScreen({super.key});

  @override
  ConsumerState<BecomeCompanionScreen> createState() => _BecomeCompanionScreenState();
}

class _BecomeCompanionScreenState extends ConsumerState<BecomeCompanionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hourlyRateController = TextEditingController(text: '500');
  final _eventRateController = TextEditingController(text: '2500');
  final _taglineController = TextEditingController();

  final List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Set<String> _selectedDays = {'Fri', 'Sat', 'Sun'};

  final List<String> _allInterests = [
    'Dinner & Cafés',
    'Movies & Theatre',
    'Weddings & Family Events',
    'Sightseeing & City Tours',
    'Concerts & Festivals',
    'Shopping & Malls',
    'Casual Walks & Parks',
    'Coffee & Conversations'
  ];
  final Set<String> _selectedInterests = {'Dinner & Cafés', 'Movies & Theatre', 'Coffee & Conversations'};

  final List<String> _allLanguages = ['English', 'Hindi', 'Marathi', 'Tamil', 'Telugu', 'Bengali', 'Gujarati', 'Kannada'];
  final Set<String> _selectedLanguages = {'English', 'Hindi'};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).user?.companionProfile;
    if (profile != null) {
      _hourlyRateController.text = profile.hourlyRate.round().toString();
      _eventRateController.text = profile.eventRate.round().toString();
      if (profile.tagline != null) _taglineController.text = profile.tagline!;
      if (profile.availableDays.isNotEmpty) {
        _selectedDays.clear();
        _selectedDays.addAll(profile.availableDays);
      }
      if (profile.interests.isNotEmpty) {
        _selectedInterests.clear();
        _selectedInterests.addAll(profile.interests);
      }
      if (profile.languages.isNotEmpty) {
        _selectedLanguages.clear();
        _selectedLanguages.addAll(profile.languages);
      }
    }
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _eventRateController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final hourly = double.tryParse(_hourlyRateController.text) ?? 500.0;
    final event = double.tryParse(_eventRateController.text) ?? 2500.0;

    setState(() => _isSubmitting = true);

    final payload = {
      'hourly_rate': hourly,
      'event_rate': event,
      'tagline': _taglineController.text.trim(),
      'available_days': _selectedDays.toList(),
      'interests': _selectedInterests.toList(),
      'languages': _selectedLanguages.toList(),
      'is_listed': true,
    };

    final isExisting = ref.read(authProvider).user?.companionProfile != null;
    final res = isExisting
        ? await ApiService().updateCompanionProfile(payload)
        : await ApiService().createCompanionProfile(payload);

    setState(() => _isSubmitting = false);

    if (res.success && mounted) {
      await ref.read(authProvider.notifier).refreshUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Companion profile published successfully!'),
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
        title: const Text('Companion Profile & Rates'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Your Rates & Availability',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Companions receive 80% of every booking. The platform keeps a 20% commission.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Rates Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hourly Rate (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _hourlyRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(prefixText: '₹ '),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Full Event Rate (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _eventRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(prefixText: '₹ '),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tagline
                const Text('Catchy Tagline / Headline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _taglineController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Friendly foodie & culture enthusiast for city events',
                  ),
                ),
                const SizedBox(height: 20),

                // Available Days
                const Text('Available Days of Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _allDays.map((day) {
                    final isSel = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: isSel,
                      selectedColor: AppColors.primary.withOpacity(0.18),
                      labelStyle: TextStyle(
                        color: isSel ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Activities
                const Text('Activities / Occasions You Attend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _allInterests.map((interest) {
                    final isSel = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSel,
                      selectedColor: AppColors.secondary.withOpacity(0.18),
                      labelStyle: TextStyle(
                        color: isSel ? AppColors.secondary : AppColors.textPrimary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Languages
                const Text('Languages Spoken', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _allLanguages.map((lang) {
                    final isSel = _selectedLanguages.contains(lang);
                    return FilterChip(
                      label: Text(lang),
                      selected: isSel,
                      selectedColor: AppColors.primary.withOpacity(0.18),
                      labelStyle: TextStyle(
                        color: isSel ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedLanguages.add(lang);
                          } else {
                            _selectedLanguages.remove(lang);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSave,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save & Publish Companion Profile'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
