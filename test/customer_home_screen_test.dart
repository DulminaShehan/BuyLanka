import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buylanka/features/auth/controllers/auth_controller.dart';
import 'package:buylanka/features/customer/addresses/controllers/address_controller.dart';
import 'package:buylanka/features/customer/favorites/controllers/favorites_controller.dart';
import 'package:buylanka/features/customer/home/controllers/customer_home_controller.dart';
import 'package:buylanka/features/customer/home/presentation/customer_home_screen.dart';
import 'package:buylanka/features/customer/notifications/controllers/notifications_controller.dart';
import 'package:buylanka/models/category_model.dart';
import 'package:buylanka/models/notification_model.dart';
import 'package:buylanka/models/product_model.dart';
import 'package:buylanka/models/profile_model.dart';
import 'package:buylanka/models/promotion_model.dart';
import 'package:buylanka/models/shop_model.dart';
import 'package:buylanka/repositories/customer_repository.dart';

// Fake Customer Repository for test isolation
class FakeCustomerRepository implements CustomerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CategoryModel>> getCategories() async {
    return const [
      CategoryModel(id: 'cat_burgers', name: 'Burgers', slug: 'burgers'),
      CategoryModel(id: 'cat_pizza', name: 'Pizza', slug: 'pizza'),
      CategoryModel(id: 'cat_rice', name: 'Rice', slug: 'rice'),
      CategoryModel(id: 'cat_kottu', name: 'Kottu', slug: 'kottu'),
      CategoryModel(id: 'cat_drinks', name: 'Drinks', slug: 'drinks'),
      CategoryModel(id: 'cat_desserts', name: 'Desserts', slug: 'desserts'),
    ];
  }

  @override
  Future<List<ShopModel>> getPopularShops({int limit = 6}) async {
    return const [
      ShopModel(
        id: 'shop_1',
        sellerId: 'seller_1',
        name: 'Niyabadawa',
        slug: 'niyabadawa',
        status: 'approved',
        rating: 4.8,
        totalReviews: 1200,
      ),
      ShopModel(
        id: 'shop_2',
        sellerId: 'seller_2',
        name: 'SmartHub',
        slug: 'smarthub',
        status: 'approved',
        rating: 4.6,
        totalReviews: 856,
      ),
    ];
  }

  @override
  Future<List<ShopModel>> getShops({String? search, String? categoryId}) async {
    return const [
      ShopModel(
        id: 'shop_1',
        sellerId: 'seller_1',
        name: 'Niyabadawa',
        slug: 'niyabadawa',
        status: 'approved',
        rating: 4.8,
        totalReviews: 1200,
      ),
      ShopModel(
        id: 'shop_2',
        sellerId: 'seller_2',
        name: 'SmartHub',
        slug: 'smarthub',
        status: 'approved',
        rating: 4.6,
        totalReviews: 856,
      ),
    ];
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    return const [
      ProductModel(
        id: 'prod_1',
        shopId: 'shop_1',
        title: 'Cheese Kottu Special',
        slug: 'cheese-kottu-special',
        price: 1400,
      ),
      ProductModel(
        id: 'prod_2',
        shopId: 'shop_2',
        title: 'Gourmet Crispy Burger',
        slug: 'gourmet-crispy-burger',
        price: 1600,
      ),
    ];
  }

  @override
  Future<List<PromotionModel>> getPromotions() async {
    return const [
      PromotionModel(
        id: 'promo_kottu',
        title: 'Kottu Nights 🌙',
        description: 'Get 20% OFF on all Kottu orders.',
        buttonText: 'Order Now',
      ),
    ];
  }
}

class FakeAuthController extends StateNotifier<AuthStateData> implements AuthController {
  FakeAuthController(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFavoritesController extends StateNotifier<FavoritesState> implements FavoritesController {
  FakeFavoritesController(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationsController extends StateNotifier<NotificationsState> implements NotificationsController {
  FakeNotificationsController(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAddressController extends StateNotifier<AddressState> implements AddressController {
  FakeAddressController(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('CustomerHomeScreen renders branded header, delivery location, search, categories, and shops', (WidgetTester tester) async {
    final fakeRepo = FakeCustomerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerRepositoryProvider.overrideWithValue(fakeRepo),
          customerHomeControllerProvider.overrideWith((ref) => CustomerHomeController(fakeRepo)),
          authControllerProvider.overrideWith((ref) => FakeAuthController(
            const AuthStateData(
              isLoading: false,
              profile: ProfileModel(
                id: 'cust_1',
                fullName: 'Amila Perera',
                email: 'amila@buylanka.lk',
                role: 'customer',
                status: 'active',
              ),
            ),
          )),
          favoritesControllerProvider.overrideWith((ref) => FakeFavoritesController(
            const FavoritesState(isLoading: false),
          )),
          notificationsControllerProvider.overrideWith((ref) => FakeNotificationsController(
            NotificationsState(
              isLoading: false,
              notifications: [
                NotificationModel(
                  id: 'notif_1',
                  userId: 'cust_1',
                  title: 'Order Delivered',
                  message: 'Your order was delivered.',
                  isRead: false,
                  createdAt: DateTime.now(),
                ),
                NotificationModel(
                  id: 'notif_2',
                  userId: 'cust_1',
                  title: 'Promo 20%',
                  message: 'Special discount today.',
                  isRead: false,
                  createdAt: DateTime.now(),
                ),
              ],
            ),
          )),
          addressControllerProvider.overrideWith((ref) => FakeAddressController(
            const AddressState(isLoading: false),
          )),
        ],
        child: const MaterialApp(
          home: CustomerHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Branded Header
    expect(find.text('BuyLanka'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // unread notification badge

    // 2. Verify Delivery Location
    expect(find.text('DELIVER TO'), findsOneWidget);
    expect(find.text('Colombo 05, Western Province'), findsOneWidget);

    // 3. Verify Search Bar
    expect(find.text('Search for food, Kottu, Burger, Rice...'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // 4. Verify Promotional Banner
    expect(find.text('Kottu Nights 🌙'), findsOneWidget);
    expect(find.text('Get 20% OFF on all Kottu orders.'), findsOneWidget);
    expect(find.text('Order Now'), findsOneWidget);

    // 5. Verify Food Categories
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Burgers'), findsOneWidget);
    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Kottu'), findsOneWidget);
    expect(find.text('Drinks'), findsOneWidget);
    expect(find.text('Desserts'), findsOneWidget);

    // 6. Verify Popular Restaurants
    expect(find.text('Popular Restaurants ⭐'), findsOneWidget);
    expect(find.text('Niyabadawa'), findsWidgets);
    expect(find.text('SmartHub'), findsWidgets);
    expect(find.text('(1.2k)'), findsWidgets);
    expect(find.text('(856)'), findsWidgets);

    // 7. Verify Recommended Section
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Recommended For You 🇱🇰'), findsOneWidget);
    expect(find.text('Cheese Kottu Special'), findsOneWidget);
    expect(find.text('Gourmet Crispy Burger'), findsOneWidget);
  });
}
