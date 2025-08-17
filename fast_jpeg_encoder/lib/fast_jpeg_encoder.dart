
import 'fast_jpeg_encoder_platform_interface.dart';

class FastJpegEncoder {
  Future<String?> getPlatformVersion() {
    return FastJpegEncoderPlatform.instance.getPlatformVersion();
  }
}
