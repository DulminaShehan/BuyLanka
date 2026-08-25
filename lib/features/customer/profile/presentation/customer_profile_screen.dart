import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/location/map_utils.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/customer/addresses/presentation/saved_addresses_screen.dart';
import 'package:buylanka/features/customer/favorites/presentation/favorites_screen.dart';
import 'package:buylanka/features/customer/notifications/presentation/notifications_screen.dart';
import 'package:buylanka/features/customer/orders/presentation/customer_orders_screen.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;
    final authNotifier = ref.read(authControllerProvider.notifier);

    final fullName = profile?.fullName ?? 'Valued Customer';
    final email = profile?.email ?? 'customer@buylanka.lk';
    final phone = profile?.phoneNumber ?? 'Not provided';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. User Avatar & Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: () => _showEditProfileDialog(context, authNotifier, fullName, phone),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Options List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.location_on_outlined,
                    title: 'Saved Addresses',
                    subtitle: 'Manage home, work & other addresses',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildProfileTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Order History',
                    subtitle: 'View active and past food deliveries',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CustomerOrdersScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildProfileTile(
                    icon: Icons.favorite_border_rounded,
                    title: 'My Favorites',
                    subtitle: 'Saved restaurants and favorite dishes',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildProfileTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Order tracking & milestone alerts',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildProfileTile(
                    icon: Icons.headset_mic_outlined,
                    title: '24/7 Customer Support',
                    subtitle: 'Call BuyLanka helpline: +94 11 200 9000',
                    onTap: () => MapUtils.makePhoneCall('+94 11 200 9000'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out?'),
                      content: const Text('Are you sure you want to sign out of your BuyLanka account?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            authNotifier.signOut();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),

            const SizedBox(height: 32),
            const Text('BuyLanka v1.0.0 • Proudly Sri Lankan 🇱🇰', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthController authNotifier, String currentName, String currentPhone) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone == 'Not provided' ? '' : currentPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await authNotifier.updateProfile(
                fullName: nameCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
