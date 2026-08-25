import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/features/customer/addresses/controllers/address_controller.dart';

class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressControllerProvider);
    final controller = ref.read(addressControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.addresses.isEmpty
              ? _buildEmptyState(context, controller)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.addresses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = state.addresses[index];
                    final isSelected = state.selectedAddress?.id == address.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          controller.selectAddress(address);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        address.label.toLowerCase() == 'home'
                                            ? Icons.home_rounded
                                            : (address.label.toLowerCase() == 'work' ? Icons.work_rounded : Icons.location_on_rounded),
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        address.label,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (address.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'DEFAULT',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'default') {
                                        controller.setDefaultAddress(address.id);
                                      } else if (val == 'delete') {
                                        controller.deleteAddress(address.id);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete Address', style: TextStyle(color: AppColors.error))),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${address.recipientName} • ${address.phoneNumber}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address.fullAddressText,
                                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                              ),
                              if (address.deliveryInstructions != null && address.deliveryInstructions!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Note: ${address.deliveryInstructions}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.info, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddAddressDialog(context, controller),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AddressController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No saved addresses yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Save your Home or Work delivery locations for fast ordering.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddAddressDialog(context, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Address'),
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context, AddressController controller) {
    final formKey = GlobalKey<FormState>();
    String label = 'Home';
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Colombo');
    final noteCtrl = TextEditingController();
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Label Selector
                  Row(
                    children: ['Home', 'Work', 'Other'].map((l) {
                      final isSel = label == l;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(l),
                          selected: isSel,
                          onSelected: (_) => setModalState(() => label = l),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Recipient Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Contact Phone Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: streetCtrl,
                    decoration: InputDecoration(
                      labelText: 'Street Address / Building',
                      hintText: 'e.g. No. 45, Galle Road, Bambalapitiya',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: cityCtrl,
                    decoration: InputDecoration(
                      labelText: 'City / District',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Delivery Instructions (Optional)',
                      hintText: 'e.g. 2nd Floor, Apt 3B',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  CheckboxListTile(
                    value: isDefault,
                    onChanged: (v) => setModalState(() => isDefault = v ?? false),
                    title: const Text('Set as default delivery address', style: TextStyle(fontSize: 13)),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          await controller.createAddress(
                            label: label,
                            recipientName: nameCtrl.text.trim(),
                            phoneNumber: phoneCtrl.text.trim(),
                            streetAddress: streetCtrl.text.trim(),
                            city: cityCtrl.text.trim(),
                            deliveryInstructions: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                            isDefault: isDefault,
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Delivery Address', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
