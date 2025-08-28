import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

class RegisterFaceDialogMacOS extends StatefulWidget {
  final String employeeId;
  final String? existingFaceUrl;

  const RegisterFaceDialogMacOS({
    super.key,
    required this.employeeId,
    this.existingFaceUrl,
  });

  @override
  State<RegisterFaceDialogMacOS> createState() =>
      _RegisterFaceDialogMacOSState();
}

class _RegisterFaceDialogMacOSState extends State<RegisterFaceDialogMacOS> {
  CameraMacOSController? _controller;
  bool _showCamera = false;
  bool _isSaving = false;
  Uint8List? _capturedBytes;

  @override
  void dispose() {
    _controller?.destroy();
    super.dispose();
  }

  Future<void> _toggleCamera(bool on) async {
    if (on == _showCamera) return;
    setState(() => _showCamera = on);
    if (!on) {
      await _controller?.destroy();
      _controller = null;
    } else {
      setState(() => _capturedBytes = null);
    }
  }

  Future<void> _capture() async {
    if (_controller == null) return;
    try {
      final CameraMacOSFile? file = await _controller!.takePicture();
      if (file?.bytes != null) {
        setState(() => _capturedBytes = file!.bytes);
        await _toggleCamera(false);
      }
    } catch (e) {
      _toast('Gagal ambil foto: $e');
    }
  }

  Future<void> _submit() async {
    if (_capturedBytes == null) return;
    setState(() => _isSaving = true);
    try {
      final decoded = img.decodeImage(_capturedBytes!);
      if (decoded == null) throw Exception('Gagal decode gambar');
      final jpgBytes = img.encodeJpg(decoded, quality: 92);

      final dio = Dio();
      final formData = FormData.fromMap({
        'employeeId': widget.employeeId,
        'image': MultipartFile.fromBytes(
          jpgBytes,
          filename: 'face-${widget.employeeId}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final res = await dio.post(
        'http://localhost:8001/api/register-face',
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (res.statusCode == 201) {
        if (mounted) Navigator.of(context).pop();
        _toast('Wajah berhasil disimpan.');
      } else {
        _toast('Gagal menyimpan (status ${res.statusCode}).');
      }
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: _Glass(
          borderRadius: 22,
          padding: const EdgeInsets.all(18),
          child: Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F9BFF), Color(0xFF3F7BFF)],
                      ),
                    ),
                    child: const Icon(Icons.face_retouching_natural,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Registrasi Wajah',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        'Posisikan wajah di tengah, pencahayaan merata, dan hindari blur.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 14),
              const _DividerLine(),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth > 720;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 11,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _Pill(
                                  icon: _capturedBytes != null
                                      ? Icons.check_circle
                                      : (widget.existingFaceUrl != null
                                          ? Icons.image
                                          : Icons.info),
                                  text: _capturedBytes != null
                                      ? 'Foto siap disimpan'
                                      : (widget.existingFaceUrl != null
                                          ? 'Wajah sudah terdaftar — bisa ganti'
                                          : 'Belum ada foto — tekan Mulai Kamera'),
                                  color: _capturedBytes != null
                                      ? Colors.green
                                      : (widget.existingFaceUrl != null
                                          ? Colors.blueGrey
                                          : Colors.orange),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(spacing: 12, runSpacing: 12, children: [
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB)),
                                onPressed: () => _toggleCamera(!_showCamera),
                                icon: Icon(
                                    _showCamera ? Icons.stop : Icons.videocam),
                                label: Text(_showCamera
                                    ? 'Matikan Kamera'
                                    : 'Mulai Kamera'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: _showCamera && _controller != null
                                    ? _capture
                                    : null,
                                icon: const Icon(Icons.camera_alt_rounded),
                                label: const Text('Ambil Foto'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _capturedBytes != null
                                    ? () async {
                                        setState(() => _capturedBytes = null);
                                        await _toggleCamera(true);
                                      }
                                    : null,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Ulangi'),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            Text('Catatan:', style: theme.textTheme.labelLarge),
                            const SizedBox(height: 6),
                            const _HintList(
                              items: [
                                'Hindari backlight kuat dari belakang.',
                                'Jaga jarak ±40–60 cm dari kamera.',
                                'Luruskan wajah, jangan terlalu miring.',
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isWide ? 18 : 0, height: isWide ? 0 : 18),
                      Flexible(
                        flex: 13,
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 240),
                                  child: _buildPreview(),
                                ),
                                IgnorePointer(
                                  child: CustomPaint(
                                    painter: _FaceGuidePainter(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              const _DividerLine(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal')),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed:
                        _capturedBytes != null && !_isSaving ? _submit : null,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan'),
                  ),
                ],
              )
            ],
          ))),
    );
  }

  Widget _buildPreview() {
    if (_capturedBytes != null) {
      return Image.memory(_capturedBytes!,
          fit: BoxFit.cover, key: const ValueKey('captured'));
    }
    if (_showCamera) {
      return ColoredBox(
        key: const ValueKey('live'),
        color: Colors.black,
        child: CameraMacOSView(
          fit: BoxFit.cover,
          cameraMode: CameraMacOSMode.photo,
          onCameraInizialized: (c) => setState(() => _controller = c),
        ),
      );
    }
    if (widget.existingFaceUrl != null) {
      return Image.network(widget.existingFaceUrl!,
          fit: BoxFit.cover, key: const ValueKey('existing'));
    }
    return const _PreviewPlaceholder(key: ValueKey('placeholder'));
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  const _Glass(
      {required this.child,
      this.borderRadius = 18,
      this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: const Color(0xFFE7ECF3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 20,
                  offset: Offset(0, 12),
                )
              ],
            ),
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDDE7F7), Color(0xFFEDF3FF)],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Pill({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          )
        ],
      ),
    );
  }
}

class _HintList extends StatelessWidget {
  final List<String> items;
  const _HintList({required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded,
                      size: 16, color: Colors.black38),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(e,
                          style: const TextStyle(color: Colors.black87))),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E0E0E),
      child: const Center(
        child: Icon(Icons.person_outline, color: Colors.white54, size: 72),
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 1.6;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final rX = size.width * 0.32;
    final rY = size.height * 0.42;

    final path = Path()
      ..addOval(Rect.fromCenter(center: center, width: rX * 2, height: rY * 2));

    final overlay = Paint()..color = Colors.black.withOpacity(0.28);
    final outer = Path()..addRect(rect);
    final clip = Path.combine(PathOperation.difference, outer, path);
    canvas.drawPath(clip, overlay);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
