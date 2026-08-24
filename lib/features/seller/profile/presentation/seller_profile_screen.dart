import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/seller/shop/controllers/shop_controller.dart';
import 'package:buylanka/features/seller/shop/presentation/shop_settings_screen.dart';

class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final shopState = ref.watch(shopControllerProvider);
    final profile = authState.profile;
    final seller = authState.seller;
    final shop = shopState.shop;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendor Profile & Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      profile?.fullName.isNotEmpty == true ? profile!.fullName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.fullName ?? 'Seller Account',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.email ?? '',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Merchant',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Business & KYC Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Business & KYC Registration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                    const Divider(height: 20),

                    _buildDetailRow('Business Name', seller?.businessName ?? shop?.name ?? '—'),
                    const SizedBox(height: 8),
                    _buildDetailRow('BR Number', seller?.businessRegistrationNumber ?? 'Not Provided'),
                    const SizedBox(height: 8),
                    _buildDetailRow('National ID (NIC)', seller?.nicNumber ?? '—'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Commission Rate', '${seller?.commissionRate ?? 10.0}%'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Account Status', profile?.status.toUpperCase() ?? 'ACTIVE'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bank Payout Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Bank Payout Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                    const Divider(height: 20),

                    _buildDetailRow('Bank Name', seller?.bankName ?? 'Commercial Bank of Ceylon'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Account Number', seller?.bankAccountNumber ?? '8001234567'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Branch', seller?.bankBranch ?? 'Colombo'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Actions
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.store_rounded, color: AppColors.primary),
                    title: const Text('Edit Shop Profile & Hours', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShopSettingsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                    title: const Text('BuyLanka Vendor Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('support@buylanka.lk • +94 11 234 5678', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger, width: 1.5),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Sign Out of Seller Account'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out?'),
                    content: const Text('Are you sure you want to sign out from your restaurant dashboard?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authControllerProvider.notifier).signOut();
                }
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
