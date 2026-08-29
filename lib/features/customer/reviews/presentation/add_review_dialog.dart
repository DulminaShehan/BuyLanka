import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buylanka/core/constants/app_colors.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/customer/shops/controllers/shop_details_controller.dart';
import 'package:buylanka/models/review_model.dart';

class AddReviewDialog extends ConsumerStatefulWidget {
  final String orderId;
  final String? shopId;
  final String? riderId;

  const AddReviewDialog({
    super.key,
    required this.orderId,
    this.shopId,
    this.riderId,
  });

  static Future<void> show(BuildContext context, {required String orderId, String? shopId, String? riderId}) {
    return showDialog(
      context: context,
      builder: (_) => AddReviewDialog(orderId: orderId, shopId: shopId, riderId: riderId),
    );
  }

  @override
  ConsumerState<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends ConsumerState<AddReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerId = ref.watch(authControllerProvider).profile?.id;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.rate_review_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Rate Your Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How was your food and delivery experience?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),

            // Star Rating Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  icon: Icon(
                    starIndex <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () => setState(() => _rating = starIndex),
                );
              }),
            ),

            const SizedBox(height: 12),

            // Comment textfield
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Share your feedback (e.g. food was hot & tasty, quick delivery!)',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textLight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surface,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || customerId == null
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  final reviewRepo = ref.read(reviewRepositoryProvider);
                  final success = await reviewRepo.submitReview(
                    ReviewModel(
                      id: '',
                      orderId: widget.orderId,
                      customerId: customerId,
                      shopId: widget.shopId,
                      riderId: widget.riderId,
                      rating: _rating,
                      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
                      createdAt: DateTime.now(),
                    ),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Thank you for your review! ⭐' : 'Review submitted successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
