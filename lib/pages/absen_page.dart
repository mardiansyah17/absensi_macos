import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_view.dart';
import 'package:face_client/frame_sender.dart';
import 'package:face_client/services/fast_jpeg_encoder.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Enums untuk status
enum CameraStatus { stopped, loading, success, error }

enum ServerStatus { connecting, success, error }

enum WelcomeStatus { defaultStatus, success, error }

// Model untuk hasil pengenalan

// ===== MODEL =====
class RecognitionResult {
  final String name;
  final BoundingBox box;
  final double? distance;

  RecognitionResult({required this.name, required this.box, this.distance});

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    return RecognitionResult(
      name: (json['name'] as String?) ?? 'unknown',
      box: BoundingBox.fromJson(
        (json['box'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      distance: (json['distance'] is num)
          ? (json['distance'] as num).toDouble()
          : null,
    );
  }
}

class BoundingBox {
  // Disimpan dalam format "pixel berbasis 640x480" supaya kompatibel
  final double left;
  final double top;
  final double right;
  final double bottom;

  BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    // Server BARU: normalized 0..1 -> {x,y,w,h}
    if (json.containsKey('x')) {
      const double baseW = 640;
      const double baseH = 480;
      final x = (json['x'] as num?)?.toDouble() ?? 0.0;
      final y = (json['y'] as num?)?.toDouble() ?? 0.0;
      final w = (json['w'] as num?)?.toDouble() ?? 0.0;
      final h = (json['h'] as num?)?.toDouble() ?? 0.0;
      final left = x * baseW;
      final top = y * baseH;
      return BoundingBox(
        left: left,
        top: top,
        right: (x + w) * baseW,
        bottom: (y + h) * baseH,
      );
    }

    // Server LAMA: {top,left,right,bottom} (pixel)
    double n(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    return BoundingBox(
      left: n(json['left']),
      top: n(json['top']),
      right: n(json['right']),
      bottom: n(json['bottom']),
    );
  }
}

// Model untuk informasi welcome
class WelcomeInfo {
  final WelcomeStatus status;
  final String title;
  final String subtitle;
  final String name;

  WelcomeInfo({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.name,
  });
}

class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({super.key});

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  // Controllers dan variabel
  final GlobalKey cameraKey = GlobalKey(debugLabel: 'cameraKey');

  CameraMacOSController? _cameraController;
  List<CameraDescription>? _cameras;
  IO.Socket? _socket;
  late FrameSender sender;
  Timer? _frameTimer;
  Timer? _clockTimer;
  Timer? _uptimeTimer;
  Timer? _welcomeTimer;

  // State variables
  bool _isCameraOn = false;
  CameraStatus _cameraStatus = CameraStatus.stopped;
  ServerStatus _serverStatus = ServerStatus.connecting;
  final String _currentTime = '';
  final String _currentDate = '';
  String _uptime = '00:00:00';
  double _latency = 0.0;
  int _uptimeSeconds = 0;
  DateTime? _lastSentTime;

  bool _sending = false;
  int _lastSendMs = 0;
  final int _minGapMs = 1000; // ~12.5 fps

  WelcomeInfo _welcomeInfo = WelcomeInfo(
    status: WelcomeStatus.defaultStatus,
    title: 'Arahkan Wajah Anda',
    subtitle: 'Sistem akan mengenali Anda secara otomatis.',
    name: '',
  );

  List<RecognitionResult> _recognitionResults = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }

  void _disposeResources() {
    _socket?.disconnect();
    _frameTimer?.cancel();
    _clockTimer?.cancel();
    _uptimeTimer?.cancel();
    _welcomeTimer?.cancel();
  }

  Future<void> _initializeApp() async {
    // await _requestPermissions();
    _initializeSocket();
    _startClock();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
  }

  void _initializeSocket() {
    _socket = IO.io('http://127.0.0.1:8001', <String, dynamic>{
      'autoConnect': true,
      'transports': ['websocket'],
      'upgrade': false,
      'forceNew': true,
    });

    _socket!.onConnect((_) {
      setState(() {
        _serverStatus = ServerStatus.success;
      });
      _startUptimeTimer();
    });

    _socket!.onDisconnect((_) {
      setState(() {
        _serverStatus = ServerStatus.error;
      });
      _stopCamera();
      _stopUptimeTimer();
    });

    _socket!.on('recognized', (data) {
      final double latency = (data['latency'] as num?)?.toDouble() ?? 0.0;
      final List resultsRaw = (data is Map && data['results'] is List)
          ? data['results'] as List
          : const [];

      setState(() {
        _latency = latency;
        _recognitionResults = resultsRaw
            .map((e) =>
                RecognitionResult.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

      _handleRecognitionResults();
    });

    _socket!.onError((error) {
      print('Socket error: $error');
      setState(() {
        _serverStatus = ServerStatus.error;
      });
    });
  }

  void _handleRecognitionResults() {
    if (_recognitionResults.isNotEmpty) {
      final person = _recognitionResults[0];
      _welcomeTimer?.cancel();

      if (person.name == 'unknown') {
        setState(() {
          _welcomeInfo = WelcomeInfo(
            status: WelcomeStatus.error,
            title: 'Wajah Tidak Dikenali',
            subtitle: 'Silakan coba lagi atau hubungi administrator.',
            name: '',
          );
        });
      } else {
        setState(() {
          _welcomeInfo = WelcomeInfo(
            status: WelcomeStatus.success,
            title: 'Selamat Datang,',
            subtitle: 'Absensi Anda telah dicatat.',
            name: person.name,
          );
        });
      }

      _welcomeTimer = Timer(const Duration(seconds: 5), () {
        setState(() {
          _welcomeInfo = WelcomeInfo(
            status: WelcomeStatus.defaultStatus,
            title: 'Arahkan Wajah Anda',
            subtitle: 'Sistem akan mengenali Anda secara otomatis.',
            name: '',
          );
        });
      });
    }
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
    });
  }

  void _startUptimeTimer() {
    _uptimeSeconds = 0;
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _uptimeSeconds++;
      final hours = (_uptimeSeconds / 3600).floor();
      final minutes = ((_uptimeSeconds % 3600) / 60).floor();
      final seconds = _uptimeSeconds % 60;

      setState(() {
        _uptime = '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}';
      });
    });
  }

  void _stopUptimeTimer() {
    _uptimeTimer?.cancel();
    setState(() {
      _uptime = '00:00:00';
    });
  }

  Future<void> _startCamera() async {
    if (_cameraController == null || _serverStatus != ServerStatus.success) {
      return;
    }

    setState(() {
      _cameraStatus = CameraStatus.loading;
    });

    try {
      setState(() {
        _cameraStatus = CameraStatus.success;
        _isCameraOn = true;
      });
    } catch (e) {
      print('Error starting camera: $e');
      setState(() {
        _cameraStatus = CameraStatus.error;
        _welcomeInfo = WelcomeInfo(
          status: WelcomeStatus.error,
          title: 'Kamera Tidak Ditemukan',
          subtitle:
              'Pastikan kamera terhubung dan izinkan akses pada aplikasi.',
          name: '',
        );
      });
    }
  }

  void _stopCamera() {
    _frameTimer?.cancel();

    setState(() {
      _cameraStatus = CameraStatus.stopped;
      _isCameraOn = false;
      _recognitionResults.clear();
    });
  }

  // Future<void> _sendFrameToServer() async {
  //   if (_cameraController == null ||
  //       !_cameraController!.value.isInitialized ||
  //       _socket == null ||
  //       !_socket!.connected) {
  //     return;
  //   }

  //   try {
  //     final image = await _cameraController!.takePicture();
  //     final bytes = await image.readAsBytes();

  //     _lastSentTime = DateTime.now();
  //     _socket!.emit('recognize', bytes);
  //   } catch (e) {
  //     print('Error sending frame: $e');
  //   }
  // }

  Color _getWelcomePanelColor() {
    switch (_welcomeInfo.status) {
      case WelcomeStatus.success:
        return Colors.green.shade100;
      case WelcomeStatus.error:
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getWelcomeTitleColor() {
    switch (_welcomeInfo.status) {
      case WelcomeStatus.success:
        return Colors.green.shade700;
      case WelcomeStatus.error:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getWelcomeSubtitleColor() {
    switch (_welcomeInfo.status) {
      case WelcomeStatus.success:
        return Colors.green.shade600;
      case WelcomeStatus.error:
        return Colors.red.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _buildDesktopLayout();
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildCameraSection(),
        ),
        Expanded(
          flex: 2,
          child: _buildInfoSection(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCameraSection(),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Uint8List convertARGBtoRGBA(Uint8List argb) {
    final length = argb.length;
    final rgba = Uint8List(length);
    for (int i = 0; i < length; i += 4) {
      rgba[i] = argb[i + 1]; // R
      rgba[i + 1] = argb[i + 2]; // G
      rgba[i + 2] = argb[i + 3]; // B
      rgba[i + 3] = argb[i]; // A
    }
    return rgba;
  }

  Widget _buildCameraSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Camera View
          Container(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 480),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      CameraMacOSView(
                        resolution: PictureResolution.low,
                        key: cameraKey,
                        fit: BoxFit.cover,
                        enableAudio: false,
                        cameraMode: CameraMacOSMode.photo,
                        onCameraInizialized:
                            (CameraMacOSController controller) {
                          controller.startImageStream(
                            (p0) async {
                              try {
                                if (_sending) return;

                                final nowMs =
                                    DateTime.now().millisecondsSinceEpoch;
                                if ((nowMs - _lastSendMs) < _minGapMs) {
                                  return; // throttle
                                }
                                if (!(_socket?.connected ?? false)) {
                                  return; // jangan antri saat socket belum konek
                                }

                                _sending = true;
                                _lastSendMs = nowMs;

                                if (p0?.bytes != null) {
                                  final width = p0!.width;
                                  final height = p0.height;
                                  final start = DateTime.now();
                                  final rgba = convertARGBtoRGBA(p0.bytes);

                                  final jpeg = await FastJpegEncoder.encodeJpeg(
                                    rgba: rgba,
                                    width: width,
                                    height: height,
                                    quality: 0.7,
                                  );

                                  print(
                                      'JPEG size: ${(jpeg.lengthInBytes / 1024).toStringAsFixed(2)} KB');
                                  final end = DateTime.now();
                                  final duration =
                                      end.difference(start).inMilliseconds;

                                  final now = DateTime.now();
                                  final formattedTime =
                                      "${now.hour}:${now.minute}:${now.second}";
                                  _socket?.emit('recognize', jpeg);
                                } else {
                                  setState(() {
                                    // image = null;
                                  });
                                }
                              } finally {
                                _sending = false;
                              }
                            },
                          );
                          setState(() {
                            _cameraController = controller;
                          });
                        },
                      ),
                      CustomPaint(
                        painter: RecognitionPainter(_recognitionResults),
                        size: Size.infinite,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Camera Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Mulai Kamera'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: !_isCameraOn ? null : _stopCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Hentikan Kamera'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // System Analytics
          _buildSystemAnalytics(),
        ],
      ),
    );
  }

  Widget _buildSystemAnalytics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analitik Sistem',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalyticsRow(
            Icons.memory,
            'Beban CPU',
            0.45,
            Colors.blue.shade600,
            '45%',
          ),
          const SizedBox(height: 12),
          _buildAnalyticsRow(
            Icons.storage,
            'Memori',
            0.60,
            Colors.green.shade600,
            '60%',
          ),
          const SizedBox(height: 12),
          _buildAnalyticsItem(
            Icons.flash_on,
            'Latensi',
            '${_latency.toStringAsFixed(2)}ms',
            Colors.yellow.shade500,
          ),
          const SizedBox(height: 12),
          _buildAnalyticsItem(
            Icons.access_time,
            'Waktu Aktif',
            _uptime,
            Colors.purple.shade500,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(
    IconData icon,
    String label,
    double progress,
    Color color,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sistem Absensi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Welcome Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _getWelcomePanelColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                if (_welcomeInfo.status == WelcomeStatus.success) ...[
                  Text(
                    'Selamat Datang,',
                    style: TextStyle(
                      fontSize: 20,
                      color: _getWelcomeTitleColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _welcomeInfo.name,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _welcomeInfo.subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _getWelcomeSubtitleColor(),
                    ),
                  ),
                ] else ...[
                  Text(
                    _welcomeInfo.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: _getWelcomeTitleColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _welcomeInfo.subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: _getWelcomeSubtitleColor(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Weather & Announcement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  size: 40,
                  color: Colors.blue.shade500,
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '31°C - Cerah Berawan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Palembang, Sumatera Selatan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              border: Border.all(color: Colors.yellow.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengumuman',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.yellow.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rapat Bulanan akan diadakan pukul 15:00 di Ruang Meeting A.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.yellow.shade700,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Clock and Status
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _currentTime,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentDate,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusIndicator(
                      _cameraStatus,
                      'Kamera',
                    ),
                    _buildStatusIndicator(
                      _serverStatus,
                      'Server',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(dynamic status, String label) {
    Color color;
    String text;
    bool shouldPulse = false;

    if (status is CameraStatus) {
      switch (status) {
        case CameraStatus.loading:
          color = Colors.yellow.shade400;
          text = '$label: Inisialisasi...';
          shouldPulse = true;
          break;
        case CameraStatus.success:
          color = Colors.green.shade500;
          text = '$label: Aktif';
          break;
        case CameraStatus.error:
          color = Colors.red.shade500;
          text = '$label: Gagal';
          break;
        case CameraStatus.stopped:
          color = Colors.grey.shade400;
          text = '$label: Dihentikan';
          break;
      }
    } else if (status is ServerStatus) {
      switch (status) {
        case ServerStatus.connecting:
          color = Colors.yellow.shade400;
          text = '$label: Menyambungkan...';
          shouldPulse = true;
          break;
        case ServerStatus.success:
          color = Colors.green.shade500;
          text = '$label: Terhubung';
          break;
        case ServerStatus.error:
          color = Colors.red.shade500;
          text = '$label: Terputus';
          break;
      }
    } else {
      color = Colors.grey.shade400;
      text = '$label: Unknown';
    }

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: shouldPulse
              ? Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class RecognitionPainter extends CustomPainter {
  final List<RecognitionResult> results;

  RecognitionPainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty) return;

    for (final result in results) {
      final isUnknown = result.name == 'unknown';
      final color = isUnknown ? Colors.red : Colors.green;
      final label = isUnknown ? 'Tidak Dikenal' : result.name;

      // Calculate scaled coordinates
      final box = result.box;
      final rect = Rect.fromLTRB(
        box.left * size.width / 640,
        box.top * size.height / 480,
        box.right * size.width / 640,
        box.bottom * size.height / 480,
      );

      // Draw bounding box
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRect(rect, paint);

      // Draw label background
      final textPainter = TextPainter(
        textDirection: ui.TextDirection.ltr,
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - 22,
        textPainter.width + 12,
        22,
      );

      canvas.drawRect(
        labelRect,
        Paint()..color = color,
      );

      // Draw label text
      textPainter.paint(canvas, Offset(rect.left + 6, rect.top - 16));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
