import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

class QrDecoder {
  /// Decodes a QR code string from raw image bytes (JPEG, PNG, WEBP, etc.).
  /// Returns the decoded text, or null if no valid QR code was detected.
  static String? decodeFromBytes(Uint8List bytes) {
    try {
      var image = img.decodeImage(bytes);
      if (image == null) return null;
      image = img.bakeOrientation(image);

      // 1. Try full image with HybridBinarizer
      String? text = _tryDecode(image, useHybrid: true);
      if (text != null && text.isNotEmpty) return _cleanDecodedText(text);

      // 2. Try full image with GlobalHistogramBinarizer
      text = _tryDecode(image, useHybrid: false);
      if (text != null && text.isNotEmpty) return _cleanDecodedText(text);

      // 3. Try cropped center (viewfinder region: 75% center crop)
      final cropW75 = (image.width * 0.75).round();
      final cropH75 = (image.height * 0.75).round();
      final cropX75 = ((image.width - cropW75) / 2).round();
      final cropY75 = ((image.height - cropH75) / 2).round();
      final cropped75 = img.copyCrop(image, x: cropX75, y: cropY75, width: cropW75, height: cropH75);

      text = _tryDecode(cropped75, useHybrid: true) ?? _tryDecode(cropped75, useHybrid: false);
      if (text != null && text.isNotEmpty) return _cleanDecodedText(text);

      // 4. Try tighter cropped center (viewfinder region: 50% center crop for close-ups)
      final cropW50 = (image.width * 0.50).round();
      final cropH50 = (image.height * 0.50).round();
      final cropX50 = ((image.width - cropW50) / 2).round();
      final cropY50 = ((image.height - cropH50) / 2).round();
      final cropped50 = img.copyCrop(image, x: cropX50, y: cropY50, width: cropW50, height: cropH50);

      text = _tryDecode(cropped50, useHybrid: true) ?? _tryDecode(cropped50, useHybrid: false);
      if (text != null && text.isNotEmpty) return _cleanDecodedText(text);

      // 5. Try resized image if large (phones take 1000px+ images)
      if (image.width > 600 || image.height > 600) {
        final resized = img.copyResize(image, width: 550);
        text = _tryDecode(resized, useHybrid: false) ?? _tryDecode(resized, useHybrid: true);
        if (text != null && text.isNotEmpty) return _cleanDecodedText(text);
      }

      // 6. Try grayscale + contrast enhancement for screen/glare photos
      final enhanced = img.contrast(img.grayscale(image), contrast: 125);
      text = _tryDecode(enhanced, useHybrid: true) ?? _tryDecode(enhanced, useHybrid: false);
      if (text != null && text.isNotEmpty) return _cleanDecodedText(text);

      // 7. Try inverted colors for dark-mode QR codes
      final inverted = img.invert(image);
      text = _tryDecode(inverted, useHybrid: true) ?? _tryDecode(inverted, useHybrid: false);
      if (text != null && text.isNotEmpty) return _cleanDecodedText(text);

      return null;
    } catch (_) {
      return null;
    }
  }

  static String? _tryDecode(img.Image image, {required bool useHybrid}) {
    // Try ABGR first (standard for little-endian int32 buffer)
    var text = _decodeSource(image, order: img.ChannelOrder.abgr, useHybrid: useHybrid);
    if (text != null && text.isNotEmpty) return text;

    // Fallback: try RGBA
    text = _decodeSource(image, order: img.ChannelOrder.rgba, useHybrid: useHybrid);
    return text;
  }

  static String? _decodeSource(img.Image image, {required img.ChannelOrder order, required bool useHybrid}) {
    try {
      final source = RGBLuminanceSource(
        image.width,
        image.height,
        image.convert(numChannels: 4).getBytes(order: order).buffer.asInt32List(),
      );
      final binarizer = useHybrid ? HybridBinarizer(source) : GlobalHistogramBinarizer(source);
      final bitmap = BinaryBitmap(binarizer);
      final reader = QRCodeReader();
      final result = reader.decode(bitmap);
      return result.text;
    } catch (_) {
      return null;
    }
  }

  static String _cleanDecodedText(String raw) {
    var text = raw.trim();
    // If the QR contains a full URL (e.g., https://.../verify?code=VERIFY-LM-...), extract parameter
    if (text.contains('code=')) {
      final match = RegExp(r'code=([^&]+)', caseSensitive: false).firstMatch(text);
      if (match != null && match.group(1) != null) {
        text = match.group(1)!;
      }
    } else if (text.contains('CODE=')) {
      final match = RegExp(r'CODE=([^&]+)').firstMatch(text);
      if (match != null && match.group(1) != null) {
        text = match.group(1)!;
      }
    } else if (text.startsWith('http://') || text.startsWith('https://')) {
      text = text.split('/').last.trim();
    }
    return text.trim();
  }
}
