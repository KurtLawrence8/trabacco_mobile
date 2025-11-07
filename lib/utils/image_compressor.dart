import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:image/image.dart' as img;

class ImageCompressor {
  static const int _maxDimension = 1280;
  static const int _defaultQuality = 80;

  static Future<Uint8List> compressBytes(
    Uint8List bytes, {
    int maxDimension = _maxDimension,
    int quality = _defaultQuality,
  }) async {
    if (bytes.isEmpty) return bytes;

    final request = _CompressRequest(
      bytes: bytes,
      maxDimension: maxDimension,
      quality: quality.clamp(1, 100),
    );

    if (kIsWeb) {
      return _performCompression(request);
    }

    return compute<_CompressRequest, Uint8List>(
      _performCompression,
      request,
    );
  }

  static Future<Uint8List> compressFile(
    Uint8List fileBytes, {
    int maxDimension = _maxDimension,
    int quality = _defaultQuality,
  }) async {
    return compressBytes(
      fileBytes,
      maxDimension: maxDimension,
      quality: quality,
    );
  }
}

class _CompressRequest {
  const _CompressRequest({
    required this.bytes,
    required this.maxDimension,
    required this.quality,
  });

  final Uint8List bytes;
  final int maxDimension;
  final int quality;
}

Uint8List _performCompression(_CompressRequest request) {
  try {
    final decoded = img.decodeImage(request.bytes);
    if (decoded == null) {
      return request.bytes;
    }

    final processed = _resizeIfNeeded(
      decoded,
      request.maxDimension,
    );

    final bytes = img.encodeJpg(
      processed,
      quality: request.quality,
    );

    return Uint8List.fromList(bytes);
  } catch (_) {
    return request.bytes;
  }
}

img.Image _resizeIfNeeded(img.Image image, int maxDimension) {
  final width = image.width;
  final height = image.height;

  if (width <= maxDimension && height <= maxDimension) {
    return image;
  }

  final aspectRatio = width / height;
  int targetWidth;
  int targetHeight;

  if (aspectRatio >= 1) {
    targetWidth = maxDimension;
    targetHeight = (maxDimension / aspectRatio).round();
  } else {
    targetHeight = maxDimension;
    targetWidth = (maxDimension * aspectRatio).round();
  }

  return img.copyResize(
    image,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.average,
  );
}

