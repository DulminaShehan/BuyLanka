import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/auth/presentation/customer_auth_screen.dart';
import 'package:buylanka/features/customer/cart/controllers/cart_controller.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/shop_model.dart';
import 'package:buylanka/main.dart';

// Fake AuthController for testing
class FakeAuthController extends StateNotifier<AuthStateData> implements AuthController {
  FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Renders Customer Auth Screen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            return FakeAuthController(
              const AuthStateData(isLoading: false, profile: null),
            );
          }),
        ],
        child: const BuyLankaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify customer auth portal elements
    expect(find.byType(CustomerAuthScreen), findsOneWidget);
    expect(find.text('BuyLanka'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  test('CartController adds and calculates items correctly', () {
    final cart = CartController();
    const shop = ShopModel(
      id: 'shop_1',
      sellerId: 'seller_1',
      name: 'Kottu Spot',
      slug: 'kottu-spot',
      status: 'approved',
      rating: 4.8,
      totalReviews: 20,
    );

    const product1 = ProductModel(
      id: 'prod_1',
      shopId: 'shop_1',
      title: 'Chicken Kottu',
      slug: 'chicken-kottu',
      price: 1200,
    );

    const product2 = ProductModel(
      id: 'prod_2',
      shopId: 'shop_1',
      title: 'Coke',
      slug: 'coke',
      price: 250,
    );

    final res1 = cart.addToCart(product: product1, shop: shop, quantity: 2);
    expect(res1, CartAddStatus.success);
    expect(cart.state.totalItemCount, 2);
    expect(cart.state.subtotal, 2400);

    final res2 = cart.addToCart(product: product2, shop: shop, quantity: 1);
    expect(res2, CartAddStatus.success);
    expect(cart.state.totalItemCount, 3);
    expect(cart.state.subtotal, 2650);
    expect(cart.state.deliveryFee, 250);
    expect(cart.state.totalAmount, 2900);
  });
}
