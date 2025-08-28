import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'fast_jpeg_encoder_method_channel.dart';

abstract class FastJpegEncoderPlatform extends PlatformInterface {
  FastJpegEncoderPlatform() : super(token: _token);

  static final Object _token = Object();

  static FastJpegEncoderPlatform _instance = MethodChannelFastJpegEncoder();

  ///

  static FastJpegEncoderPlatform get instance => _instance;

  static set instance(FastJpegEncoderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
