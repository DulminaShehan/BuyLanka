import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/core/utils/currency_formatter.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/customer/addresses/controllers/address_controller.dart';
import 'package:buylanka/features/customer/addresses/presentation/saved_addresses_screen.dart';
import 'package:buylanka/features/customer/cart/controllers/cart_controller.dart';
import 'package:buylanka/features/customer/orders/controllers/customer_orders_controller.dart';
import 'package:buylanka/features/customer/tracking/presentation/live_order_tracking_screen.dart';
import 'package:buylanka/models/address_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPaymentMethod = 'cod'; // 'cod' or 'card'
  final _notesController = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final addressState = ref.watch(addressControllerProvider);
    final profile = ref.watch(authControllerProvider).profile;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Your cart is empty')),
      );
    }

    final selectedAddress = addressState.selectedAddress;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Delivery Address Card
            _buildAddressSection(context, addressState, selectedAddress, profile),

            const SizedBox(height: 16),

            // 2. Payment Method Card
            _buildPaymentMethodSection(),

            const SizedBox(height: 16),

            // 3. Customer Notes
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
                  const Text('Delivery Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Ring the doorbell, leave at the gate',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Order Summary
            _buildOrderSummarySection(cart),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : () => _handlePlaceOrder(cart, selectedAddress, profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(CurrencyFormatter.formatLKR(cart.totalAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, AddressState addressState, AddressModel? selectedAddress, dynamic profile) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
                  );
                },
                child: Text(addressState.addresses.isEmpty ? '+ Add' : 'Change', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const Divider(height: 16),
          if (selectedAddress != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    selectedAddress.label.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  selectedAddress.recipientName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text('(${selectedAddress.phoneNumber})', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              selectedAddress.fullAddressText,
              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profile != null ? 'Using default location (Colombo 05)' : 'Please add a delivery address',
                    style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
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
          const Row(
            children: [
              Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const Divider(height: 16),
          RadioListTile<String>(
            value: 'cod',
            groupValue: _selectedPaymentMethod,
            onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Pay with cash when rider arrives with your food', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            secondary: const Icon(Icons.money_rounded, color: AppColors.success),
          ),
          const Divider(height: 10),
          RadioListTile<String>(
            value: 'card',
            groupValue: _selectedPaymentMethod,
            onChanged: null, // Online card gateway placeholder
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                const Text('Credit / Debit Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4)),
                  child: const Text('Coming Soon', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                ),
              ],
            ),
            subtitle: const Text('Visa, Mastercard, LankaPay online processing', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            secondary: const Icon(Icons.credit_card_rounded, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection(dynamic cart) {
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
          Text(
            'Order from: ${cart.shop?.name}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const Divider(height: 16),
          ...cart.items.map<Widget>((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.quantity}x ${item.product.title}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    CurrencyFormatter.formatLKR(item.totalPrice),
                    style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Item Subtotal', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
              Text(CurrencyFormatter.formatLKR(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery Fee', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
              Text(CurrencyFormatter.formatLKR(cart.deliveryFee), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text(
                CurrencyFormatter.formatLKR(cart.totalAmount),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlaceOrder(dynamic cart, AddressModel? selectedAddress, dynamic profile) async {
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order')),
      );
      return;
    }

    final shippingAddress = {
      'recipient_name': selectedAddress?.recipientName ?? profile.fullName,
      'phone_number': selectedAddress?.phoneNumber ?? profile.phoneNumber ?? '+94 77 123 4567',
      'street_address': selectedAddress?.streetAddress ?? 'Colombo 05',
      'city': selectedAddress?.city ?? 'Colombo',
      'district': selectedAddress?.district ?? 'Colombo District',
      'latitude': selectedAddress?.latitude ?? 6.8905,
      'longitude': selectedAddress?.longitude ?? 79.8732,
    };

    setState(() => _isPlacingOrder = true);

    try {
      final orderRepo = ref.read(customerOrderRepositoryProvider);
      final placedOrder = await orderRepo.placeOrder(
        customerId: profile.id,
        shopId: cart.shop!.id,
        shippingAddress: shippingAddress,
        items: cart.items,
        customerNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
        deliveryFee: cart.deliveryFee,
        discountAmount: cart.discountAmount,
      );

      // Clear cart
      ref.read(cartControllerProvider.notifier).clearCart();
      ref.read(customerOrdersControllerProvider.notifier).loadOrders();

      if (mounted) {
        setState(() => _isPlacingOrder = false);

        // Show confirmation and open Live Tracking
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
                SizedBox(height: 12),
                Text('Order Confirmed 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Your order #${placedOrder.orderNumber} has been received by ${cart.shop!.name}.\nEstimated delivery in 25-35 mins.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => LiveOrderTrackingScreen(orderId: placedOrder.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Track Live Delivery 🚴', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
