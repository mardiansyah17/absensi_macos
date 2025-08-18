import 'package:flutter/services.dart';

class FastJpegEncoder {
  static const _channel = MethodChannel('fast_jpeg_encoder');

  static Future<Uint8List> encodeJpeg({
    required Uint8List rgba,
    required int width,
    required int height,
    double quality = 0.7,
  }) async {
    final result = await _channel.invokeMethod<Uint8List>(
      'encodeJpeg',
      {
        'rgba': rgba,
        'width': width,
        'height': height,
      },
    );
    return result!;
  }
}
