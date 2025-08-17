// socket_frame_sender.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:face_client/services/fast_jpeg_encoder.dart';

class FrameSender {
  final String serverUrl;
  final int frameIntervalMs; // kirim max 1x per interval
  final double jpegQuality; // 0.6–0.7 disarankan
  late IO.Socket _socket;

  bool _inFlight = false;
  int _lastSentAt = 0;

  FrameSender({
    required this.serverUrl,
    this.frameIntervalMs = 1000,
    this.jpegQuality = 0.7,
  });

  void init() {
    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // PENTING: hindari long-polling
          .setTimeout(20000)
          .build(),
    );

    _socket.onConnect((_) => print('[socket] connected'));
    _socket.onConnectError((e) => print('[socket] connect error: $e'));
    _socket.onError((e) => print('[socket] error: $e'));

    // Server harus balas event ini (lihat snippet Node opsional di bawah)
    _socket.on('recognized', (data) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sentAt = (data is Map && data['t'] is int) ? data['t'] as int : 0;
      if (sentAt > 0) {
        print('[E2E] ${now - sentAt} ms');
      }
      _inFlight = false; // izinkan frame berikutnya
    });
  }

  bool get connected => _socket.connected;

  /// Panggil fungsi ini dari callback frame kamera (RGBA, 8-bit, BGRA/RGBA terserah encoder-mu).
  Future<void> onCameraFrame(Uint8List rgba, int width, int height) async {
    if (!_socket.connected) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_inFlight || (now - _lastSentAt) < frameIntervalMs) {
      return; // throttle + backpressure
    }

    _inFlight = true;
    _lastSentAt = now;

    try {
      // Encode JPEG kualitas rendah biar payload kecil
      final jpeg = await FastJpegEncoder.encodeJpeg(
        rgba: rgba,
        width: width,
        height: height,
      );

      final t = DateTime.now().millisecondsSinceEpoch; // timestamp sebelum emit
      _socket.emit('recognize', {
        't': t,
        'jpg':
            jpeg, // kirim sebagai binary (socket.io-client Dart handle otomatis)
      });
    } catch (e) {
      print('[encode/send] error: $e');
      _inFlight = false; // supaya tidak macet
    }
  }

  void dispose() {
    _socket.dispose();
  }
}
