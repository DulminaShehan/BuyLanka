import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class StorageRepository {
  final SupabaseClient _client;

  StorageRepository([SupabaseClient? client]) : _client = client ?? SupabaseService.client;

  Future<String?> uploadAvatar({
    required XFile file,
    required String userId,
  }) async {
    final bytes = await file.readAsBytes();
    final fileExt = file.name.split('.').last.toLowerCase();
    final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final contentType = _getContentType(fileExt);

    // 1. Try common Supabase Storage bucket names
    final candidateBuckets = ['avatars', 'profiles', 'public', 'images'];
    for (final bucket in candidateBuckets) {
      try {
        await _client.storage.from(bucket).uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
        return _client.storage.from(bucket).getPublicUrl(fileName);
      } catch (_) {
        // Try next candidate bucket
      }
    }

    // 2. Fallback: Return Base64 Data URI if storage bucket hasn't been created yet
    final base64String = base64Encode(bytes);
    return 'data:$contentType;base64,$base64String';
  }

  Future<String?> uploadImage({
    required String bucket,
    required XFile file,
    String? folder,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
      final filePath = folder != null ? '$folder/$fileName' : fileName;

      final contentType = _getContentType(fileExt);

      await _client.storage.from(bucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      final publicUrl = _client.storage.from(bucket).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      // If storage bucket is not created or permissions error, fallback or throw
      rethrow;
    }
  }

  Future<String?> uploadBytes({
    required String bucket,
    required Uint8List bytes,
    required String fileName,
    String? folder,
  }) async {
    try {
      final filePath = folder != null ? '$folder/$fileName' : fileName;
      final fileExt = fileName.split('.').last.toLowerCase();

      await _client.storage.from(bucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(fileExt),
          upsert: true,
        ),
      );

      return _client.storage.from(bucket).getPublicUrl(filePath);
    } catch (e) {
      rethrow;
    }
  }

  String _getContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
