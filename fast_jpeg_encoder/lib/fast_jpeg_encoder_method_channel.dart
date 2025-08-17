import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fast_jpeg_encoder_platform_interface.dart';

/// An implementation of [FastJpegEncoderPlatform] that uses method channels.
class MethodChannelFastJpegEncoder extends FastJpegEncoderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('fast_jpeg_encoder');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
