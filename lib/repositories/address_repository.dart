import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buylanka/core/constants/supabase_constants.dart';
import 'package:buylanka/models/address_model.dart';
import 'package:buylanka/services/supabase_service.dart';

class AddressRepository {
  final SupabaseClient _client;

  AddressRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  /// Fetch all saved addresses for customer
  Future<List<AddressModel>> getCustomerAddresses(String customerId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.customerAddressesTable)
          .select()
          .eq('customer_id', customerId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (data as List).map((a) => AddressModel.fromJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Create new delivery address
  Future<AddressModel?> createAddress(AddressModel address) async {
    try {
      if (address.isDefault) {
        // Unset previous defaults
        await _client
            .from(SupabaseConstants.customerAddressesTable)
            .update({'is_default': false})
            .eq('customer_id', address.customerId);
      }

      final data = await _client
          .from(SupabaseConstants.customerAddressesTable)
          .insert(address.toJson())
          .select()
          .single();

      return AddressModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Update existing delivery address
  Future<void> updateAddress(AddressModel address) async {
    if (address.isDefault) {
      await _client
          .from(SupabaseConstants.customerAddressesTable)
          .update({'is_default': false})
          .eq('customer_id', address.customerId);
    }

    await _client
        .from(SupabaseConstants.customerAddressesTable)
        .update(address.toJson())
        .eq('id', address.id);
  }

  /// Delete address
  Future<void> deleteAddress(String addressId) async {
    await _client
        .from(SupabaseConstants.customerAddressesTable)
        .delete()
        .eq('id', addressId);
  }

  /// Set default address
  Future<void> setDefaultAddress(String customerId, String addressId) async {
    await _client
        .from(SupabaseConstants.customerAddressesTable)
        .update({'is_default': false})
        .eq('customer_id', customerId);

    await _client
        .from(SupabaseConstants.customerAddressesTable)
        .update({'is_default': true})
        .eq('id', addressId);
  }
}
