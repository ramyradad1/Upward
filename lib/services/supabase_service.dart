import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SupabaseService {
  static const String supabaseUrl = 'https://zbnhiiezhgxpsltqcypc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpibmhpaWV6aGd4cHNsdHFjeXBjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MzI4NzAsImV4cCI6MjA4NjIwODg3MH0.wLmoenaXPFv7kcgwEGNUlNcUyj-X0dnQ1WzIx9gRxqM';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static Future<String> uploadImage(XFile file, String folderPath) async {
    // Create a unique file name
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fullPath = '$folderPath/$fileName';
    
    // Read bytes
    Uint8List bytes = await file.readAsBytes();
    
    debugPrint('Uploading image: $fullPath (${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB)');

    // Compress on-device using image_picker's maxWidth/maxHeight
    // (already set in _pickImage). If still large, do a simple quality reduction.
    // flutter_image_compress can crash on some devices, so we removed it.

    // Upload file to 'asset_images' bucket
    try {
      await client.storage.from('asset_images').uploadBinary(
        fullPath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
    } catch (e) {
      debugPrint('Upload error: $e');
      // If file exists, try with upsert
      if (e.toString().contains('Duplicate') || e.toString().contains('already exists')) {
        await client.storage.from('asset_images').uploadBinary(
          fullPath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
      } else {
        rethrow;
      }
    }

    // Get public URL
    final imageUrl = client.storage.from('asset_images').getPublicUrl(fullPath);
    debugPrint('Upload success: $imageUrl');
    return imageUrl;
  }

  static Future<String> uploadFile(PlatformFile file, String folderPath) async {
    // Create a unique file name
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final fullPath = '$folderPath/$fileName';
    
    // Upload file to 'asset_docs' bucket
    try {
      if (kIsWeb) {
        await client.storage.from('asset_docs').uploadBinary(
          fullPath,
          file.bytes!,
          fileOptions: const FileOptions(upsert: true),
        );
      } else {
        await client.storage.from('asset_docs').upload(
          fullPath,
          File(file.path!),
          fileOptions: const FileOptions(upsert: true),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (e.toString().contains('Duplicate') || e.toString().contains('already exists')) {
        if (kIsWeb) {
           await client.storage.from('asset_docs').uploadBinary(
            fullPath,
            file.bytes!,
            fileOptions: const FileOptions(upsert: true),
          );
        } else {
           await client.storage.from('asset_docs').upload(
            fullPath,
            File(file.path!),
            fileOptions: const FileOptions(upsert: true),
          );
        }
      } else {
        rethrow;
      }
    }

    // Get public URL
    // Note: For sensitive docs, we might want createSignedUrl instead, but the requirement says "download button".
    // Assuming public bucket for now as per plan implicitly (since no auth mentioned for download).
    final fileUrl = client.storage.from('asset_docs').getPublicUrl(fullPath);
    debugPrint('Upload success: $fileUrl');
    return fileUrl;
  }
}
