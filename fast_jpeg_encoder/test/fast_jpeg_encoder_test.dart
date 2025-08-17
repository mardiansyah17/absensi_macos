import 'package:flutter_test/flutter_test.dart';
import 'package:fast_jpeg_encoder/fast_jpeg_encoder.dart';
import 'package:fast_jpeg_encoder/fast_jpeg_encoder_platform_interface.dart';
import 'package:fast_jpeg_encoder/fast_jpeg_encoder_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFastJpegEncoderPlatform
    with MockPlatformInterfaceMixin
    implements FastJpegEncoderPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FastJpegEncoderPlatform initialPlatform = FastJpegEncoderPlatform.instance;

  test('$MethodChannelFastJpegEncoder is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFastJpegEncoder>());
  });

  test('getPlatformVersion', () async {
    FastJpegEncoder fastJpegEncoderPlugin = FastJpegEncoder();
    MockFastJpegEncoderPlatform fakePlatform = MockFastJpegEncoderPlatform();
    FastJpegEncoderPlatform.instance = fakePlatform;

    expect(await fastJpegEncoderPlugin.getPlatformVersion(), '42');
  });
}
