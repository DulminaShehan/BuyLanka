import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/delivery_model.dart';
import 'package:buylanka/models/rider_earnings_model.dart';
import 'package:buylanka/models/rider_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class RiderRepository {
  final SupabaseClient _client;

  RiderRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  /// Fetch rider record by profile ID
  Future<RiderModel?> getRiderById(String riderId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.ridersTable)
          .select()
          .eq('id', riderId)
          .maybeSingle();

      if (data == null) return null;
      return RiderModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Create default rider record if missing
  Future<RiderModel> createDefaultRiderRecord({
    required String riderId,
    String vehicleType = 'motorcycle',
    String vehicleNumber = 'WP BCD-1234',
    String drivingLicenseNumber = 'B1234567',
  }) async {
    final payload = {
      'id': riderId,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'driving_license_number': drivingLicenseNumber,
      'assigned_zone': 'Colombo District',
      'availability_status': 'offline',
      'verification_status': 'approved',
      'rating': 5.0,
      'total_deliveries': 0,
      'is_online': false,
    };

    final data = await _client
        .from(SupabaseConstants.ridersTable)
        .upsert(payload)
        .select()
        .single();

    return RiderModel.fromJson(data);
  }

  /// Toggle Online / Offline status
  Future<void> toggleOnlineStatus(String riderId, bool isOnline) async {
    final status = isOnline ? 'available' : 'offline';
    try {
      await _client.from(SupabaseConstants.ridersTable).upsert({
        'id': riderId,
        'is_online': isOnline,
        'availability_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      try {
        await _client.from(SupabaseConstants.ridersTable).update({
          'is_online': isOnline,
          'availability_status': status,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', riderId);
      } catch (_) {}
    }
  }

  /// Update live GPS position
  Future<void> updateLocation({
    required String riderId,
    required double latitude,
    required double longitude,
    String? deliveryId,
    double? heading,
    double? speed,
  }) async {
    try {
      // 1. Update rider current coordinates
      await _client.from(SupabaseConstants.ridersTable).update({
        'current_latitude': latitude,
        'current_longitude': longitude,
        'last_location_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', riderId);

      // 2. Insert breadcrumb to rider_locations if available
      try {
        await _client.from(SupabaseConstants.riderLocationsTable).insert({
          'rider_id': riderId,
          'delivery_id': deliveryId,
          'latitude': latitude,
          'longitude': longitude,
          'heading': heading,
          'speed': speed,
        });
      } catch (_) {
        // Suppress if table migration has not been run
      }
    } catch (e) {
      // Suppress network jitter errors
    }
  }

  /// Fetch all deliveries assigned to this rider
  Future<List<DeliveryModel>> getAssignedDeliveries(String riderId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.deliveriesTable)
          .select('''
            *,
            order:${SupabaseConstants.ordersTable}!order_id(
              *,
              order_items:${SupabaseConstants.orderItemsTable}(*),
              shop:${SupabaseConstants.shopsTable}!shop_id(*),
              customer:${SupabaseConstants.profilesTable}!customer_id(*)
            )
          ''')
          .eq('rider_id', riderId)
          .order('created_at', ascending: false);

      return (data as List).map((d) => DeliveryModel.fromJson(d as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Realtime stream of assigned deliveries
  Stream<List<Map<String, dynamic>>> streamRiderDeliveries(String riderId) {
    return _client
        .from(SupabaseConstants.deliveriesTable)
        .stream(primaryKey: ['id'])
        .eq('rider_id', riderId)
        .order('created_at', ascending: false);
  }

  /// Advance delivery status through the 8-step workflow
  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String orderId,
    required String newStatus,
  }) async {
    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{
      'delivery_status': newStatus,
      'updated_at': now,
    };

    if (newStatus == 'accepted') {
      updates['assigned_at'] = now;
    } else if (newStatus == 'picked_up') {
      updates['picked_up_at'] = now;
    } else if (newStatus == 'delivered') {
      updates['delivered_at'] = now;
    }

    // 1. Update delivery record
    await _client.from(SupabaseConstants.deliveriesTable).update(updates).eq('id', deliveryId);

    // 2. Synchronize main order status
    try {
      String orderStatus = 'processing';
      if (newStatus == 'picked_up' || newStatus == 'going_to_customer' || newStatus == 'arrived_at_customer') {
        orderStatus = 'shipped';
      } else if (newStatus == 'delivered') {
        orderStatus = 'delivered';
      } else if (newStatus == 'cancelled') {
        orderStatus = 'cancelled';
      }

      await _client.from(SupabaseConstants.ordersTable).update({
        'order_status': orderStatus,
        'updated_at': now,
      }).eq('id', orderId);
    } catch (_) {
      // Suppress if order status constraint differs
    }
  }

  /// Aggregate real rider earnings from completed deliveries
  Future<RiderEarningsModel> getRiderEarnings(String riderId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.deliveriesTable)
          .select('''
            *,
            order:${SupabaseConstants.ordersTable}!order_id(total_amount, delivery_fee)
          ''')
          .eq('rider_id', riderId)
          .eq('delivery_status', 'delivered');

      final deliveries = (data as List).map((d) => DeliveryModel.fromJson(d as Map<String, dynamic>)).toList();

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      double todaySum = 0;
      int todayCount = 0;
      double weekSum = 0;
      int weekCount = 0;
      double monthSum = 0;
      int monthCount = 0;
      double totalSum = 0;

      for (final del in deliveries) {
        final fee = del.order?.deliveryFee ?? 350.0;
        final date = del.deliveredAt ?? del.createdAt ?? DateTime.now();

        totalSum += fee;

        if (date.isAfter(startOfToday)) {
          todaySum += fee;
          todayCount++;
        }
        if (date.isAfter(startOfWeek)) {
          weekSum += fee;
          weekCount++;
        }
        if (date.isAfter(startOfMonth)) {
          monthSum += fee;
          monthCount++;
        }
      }

      return RiderEarningsModel(
        todayEarnings: todaySum,
        todayDeliveriesCount: todayCount,
        weeklyEarnings: weekSum,
        weeklyDeliveriesCount: weekCount,
        monthlyEarnings: monthSum,
        monthlyDeliveriesCount: monthCount,
        totalEarnings: totalSum,
        totalDeliveriesCount: deliveries.length,
      );
    } catch (e) {
      return const RiderEarningsModel();
    }
  }
}
