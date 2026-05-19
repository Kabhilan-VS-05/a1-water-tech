import 'dart:convert';
import 'package:flutter/material.dart';

/// Base URL of the website — used to resolve relative image paths from synced products.
const String _websiteBase = 'https://a1watertech.in';

/// API base for presigned URL requests.
const String _adminApiUrl =
    'https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod/admin';

/// Converts a raw imageUrl (which may be relative, absolute, or a data URI)
/// into a fully-qualified URL the app can display.
String resolveImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();
  if (trimmed.startsWith('data:image')) return trimmed; // Base64 data URI
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed; // Already absolute
  }
  // Relative path (e.g. "/A1 AquaShield RO.png" or "catalog/image.png") — prefix website base
  final encodedParts = trimmed.split('/').map((p) => p.isEmpty ? '' : Uri.encodeComponent(p)).toList();
  final encoded = encodedParts.join('/');
  
  if (encoded.startsWith('/')) {
    return '$_websiteBase$encoded';
  } else {
    return '$_websiteBase/$encoded';
  }
}

class ImageHelper {
  /// Returns the right [ImageProvider] for any URL type.
  static ImageProvider? getImageProvider(String? url) {
    final resolved = resolveImageUrl(url);
    if (resolved.isEmpty) return null;
    try {
      if (resolved.startsWith('data:image')) {
        final base64String = resolved.split(',').last;
        return MemoryImage(base64Decode(base64String));
      }
      return NetworkImage(resolved);
    } catch (_) {
      return null;
    }
  }

  /// Builds an [Image] widget from any URL type, with a placeholder.
  static Widget buildImage(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    final resolved = resolveImageUrl(url);
    final fallback = placeholder ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFFE0E7FF),
          child: const Icon(Icons.image_outlined, color: Color(0xFF4F46E5)),
        );

    if (resolved.isEmpty) return fallback;

    try {
      if (resolved.startsWith('data:image')) {
        final bytes = base64Decode(resolved.split(',').last);
        return Image.memory(bytes, width: width, height: height, fit: fit,
            errorBuilder: (_, _, _) => fallback);
      }
      return Image.network(
        resolved,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFE0E7FF),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4F46E5),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => fallback,
      );
    } catch (_) {
      return fallback;
    }
  }

  /// Returns the presigned-URL API endpoint string (used by the catalog screen).
  static String get presignedUrlEndpoint => '$_adminApiUrl/catalog/upload-url';
}
