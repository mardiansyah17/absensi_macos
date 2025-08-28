import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fast_jpeg_encoder_platform_interface.dart';

class MethodChannelFastJpegEncoder extends FastJpegEncoderPlatform {
  final methodChannel = const MethodChannel('fast_jpeg_encoder');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
