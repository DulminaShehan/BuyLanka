import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/location/map_utils.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/auth/presentation/seller_login_screen.dart';

class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;
    final rider = authState.rider;

    final fullName = profile?.fullName ?? 'BuyLanka Rider';
    final email = profile?.email ?? 'rider@buylanka.lk';
    final phone = profile?.phoneNumber ?? '+94 77 123 4567';
    final vehicleType = rider?.vehicleTypeDisplay ?? 'Motorbike';
    final vehicleNumber = rider?.vehicleNumber ?? 'WP BCD-1234';
    final licenseNumber = rider?.drivingLicenseNumber ?? 'B1234567';
    final zone = rider?.assignedZone ?? 'Colombo District';
    final rating = rider?.rating ?? 5.0;
    final tripsCount = rider?.totalDeliveries ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rider Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Profile Avatar & Name Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Verified BuyLanka Rider',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Rating & Career Stats
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Rating',
                    value: '⭐ ${rating.toStringAsFixed(1)}',
                    subtitle: 'Customer reviews',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Total Trips',
                    value: tripsCount.toString(),
                    subtitle: 'Deliveries done',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. Vehicle & Registration Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vehicle & License Info',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const Divider(height: 20),
                  _buildDetailRow('Vehicle Type', vehicleType, icon: Icons.motorcycle_rounded),
                  _buildDetailRow('Vehicle Plate', vehicleNumber, icon: Icons.confirmation_number_outlined),
                  _buildDetailRow('Driving License', licenseNumber, icon: Icons.badge_outlined),
                  _buildDetailRow('Operational Zone', zone, icon: Icons.map_outlined),
                  _buildDetailRow('Contact Phone', phone, icon: Icons.phone_outlined),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Support & Legal
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                    title: const Text('Rider Operations Hotline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('+94 11 234 5678 • 24/7 Delivery dispatch support', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.call_rounded, color: AppColors.success, size: 20),
                    onTap: () => MapUtils.makePhoneCall('+94112345678'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: AppColors.textLight),
                    title: const Text('Rider Safety & Guidelines', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out from your rider account?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SellerLoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
