import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'fast_jpeg_encoder_method_channel.dart';

abstract class FastJpegEncoderPlatform extends PlatformInterface {
  /// Constructs a FastJpegEncoderPlatform.
  FastJpegEncoderPlatform() : super(token: _token);

  static final Object _token = Object();

  static FastJpegEncoderPlatform _instance = MethodChannelFastJpegEncoder();

  /// The default instance of [FastJpegEncoderPlatform] to use.
  ///
  /// Defaults to [MethodChannelFastJpegEncoder].
  static FastJpegEncoderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FastJpegEncoderPlatform] when
  /// they register themselves.
  static set instance(FastJpegEncoderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
