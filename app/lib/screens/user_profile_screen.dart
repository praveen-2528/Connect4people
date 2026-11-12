import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'become_companion_screen.dart';
import 'companion_dashboard_screen.dart';
import 'profile_setup_screen.dart';
import 'auth_screen.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isCompanion = user?.isCompanion == true || user?.companionProfile != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // User Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                              ? Text(
                                  (user?.name != null && user!.name!.isNotEmpty) ? user.name![0] : 'U',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                                )
                              : null,
                        ),
                        GestureDetector(
                          onTap: () => _showAddPhotoDialog(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'Community Member',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    // Badges
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildBadge(Icons.check_circle_rounded, 'Verified Member', AppColors.success),
                        if (isCompanion)
                          _buildBadge(Icons.star_rounded, 'Active Companion', AppColors.secondary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Companion Mode Banner / Card
              if (isCompanion) ...[
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.dashboard_rounded, color: AppColors.secondary),
                    ),
                    title: const Text('Companion Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('View earnings, rates, and incoming requests'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CompanionDashboardScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Want to earn as a Companion?',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Set your hourly rate, accept booking requests on your schedule, and keep 80% payout.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.secondary,
                          minimumSize: const Size.fromHeight(42),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BecomeCompanionScreen()),
                          );
                        },
                        child: const Text('Become a Companion'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Details & Preferences
              Card(
                child: Column(
                  children: [
                    if (user?.city != null)
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                        title: const Text('City'),
                        trailing: Text(user!.city!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    if (user?.gender != null)
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                        title: const Text('Gender'),
                        trailing: Text(user!.gender!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    if (user?.phone != null && user!.phone!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                        title: const Text('Phone'),
                        trailing: Text(user.phone!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Safety Guidelines & Rules Card
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
                      title: const Text('Community & Safety Guidelines'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Safety & Guidelines'),
                            content: const SingleChildScrollView(
                              child: Text(
                                '• Connect4People is strictly for social events, outings, and friendly companionship.\n\n'
                                '• Sexual services are strictly prohibited and will result in permanent ban and legal reporting.\n\n'
                                '• Always meet in public places (malls, cafés, restaurants).\n\n'
                                '• Inform a friend or family member about your meetup details.\n\n'
                                '• Respect personal boundaries and platform rules at all times.',
                                style: TextStyle(fontSize: 13, height: 1.5),
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Understood')),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.help_outline_rounded, color: AppColors.textSecondary),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Support email: support@connect4people.com')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Logout Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddPhotoDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final presets = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&q=80',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Profile & Feed Photo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Companions and clients will see this photo on your profile and booking requests.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text('Photo Image URL', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'https://example.com/photo.jpg',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Or pick a stylish preset:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: presets.map((url) {
                  return GestureDetector(
                    onTap: () => controller.text = url,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isEmpty) return;
              Navigator.of(ctx).pop();

              final res = await ApiService().addPhoto(url);
              if (res.success && context.mounted) {
                await ref.read(authProvider.notifier).refreshUser();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo added! Companions can now see your photo in the feed & profile.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Save Photo'),
          ),
        ],
      ),
    );
  }
}
