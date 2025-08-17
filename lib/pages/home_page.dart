import 'dart:typed_data';

import 'package:camera_macos/camera_macos.dart';
import 'package:face_client/services/fast_jpeg_encoder.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey cameraKey = GlobalKey(debugLabel: 'cameraKey');
  late CameraMacOSController macOSController;
  late IO.Socket socket;
  String? image;
  List<Rect> detectedFaces = [];

  @override
  void initState() {
    super.initState();

    socket = IO.io(
      'http://localhost:8001',
      OptionBuilder().setTransports(['websocket']).build(),
    );

    socket.on("faces", (data) {
      // Ubah List<dynamic> ke List<Rect>
      List<dynamic> raw = data as List<dynamic>;
      final List<Rect> boxes = raw.map((face) {
        final x = face['_x'] as double;
        final y = face['_y'] as double;
        final w = face['_width'] as double;
        final h = face['_height'] as double;
        return Rect.fromLTWH(x, y, w, h);
      }).toList();

      setState(() {
        detectedFaces = boxes;
      });

      print("👤 Detected ${boxes.length} face(s)");
    });

    socket.onConnect((_) {
      print('Connected to socket server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from socket server');
    });
  }

  Rect mapRectToWidget(Rect faceRect, Size imageSize, Size widgetSize) {
    final imageAspect = imageSize.width / imageSize.height;
    final widgetAspect = widgetSize.width / widgetSize.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspect > widgetAspect) {
      // Image is wider: fit width
      scale = widgetSize.width / imageSize.width;
      final scaledHeight = imageSize.height * scale;
      offsetY = (widgetSize.height - scaledHeight) / 2;
    } else {
      // Image is taller: fit height
      scale = widgetSize.height / imageSize.height;
      final scaledWidth = imageSize.width * scale;
      offsetX = (widgetSize.width - scaledWidth) / 2;
    }

    return Rect.fromLTWH(
      faceRect.left * scale + offsetX,
      faceRect.top * scale + offsetY,
      faceRect.width * scale,
      faceRect.height * scale,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraMacOSView(
            key: cameraKey,
            fit: BoxFit.contain,
            enableAudio: false,
            cameraMode: CameraMacOSMode.photo,
            onCameraInizialized: (CameraMacOSController controller) {
              controller.startImageStream(
                (p0) async {
                  if (p0?.bytes != null) {
                    final width = p0!.width;
                    final height = p0.height;
                    final start = DateTime.now();
                    final rgba = convertARGBtoRGBA(p0.bytes);
                    final image = img.Image.fromBytes(
                      width: p0.width,
                      height: p0.height,
                      bytes: rgba.buffer,
                      numChannels: 4,
                    );
                    final jpeg = await FastJpegEncoder.encodeJpeg(
                      rgba: rgba,
                      width: width,
                      height: height,
                    );

                    final end = DateTime.now();
                    final duration = end.difference(start).inMilliseconds;
                    print("⏱️ Waktu proses & kirim: ${duration}ms");

                    final jpegSize = jpeg.lengthInBytes;
                    // print dalam ukuran kb
                    print("📏 Ukuran JPEG: ${jpegSize / 1024} KB");
                    final now = DateTime.now();
                    final formattedTime =
                        "${now.hour}:${now.minute}:${now.second}";
                    socket.emit('recognize', jpeg);
                  } else {
                    setState(() {
                      image = null;
                    });
                  }
                },
              );
              setState(() {
                macOSController = controller;
              });
            },
          ),
          ...detectedFaces.map((rect) {
            final renderBox =
                cameraKey.currentContext?.findRenderObject() as RenderBox?;
            final widgetSize = renderBox?.size ?? Size.zero;

            // Gunakan ukuran asli gambar dari stream
            final imageSize = Size(
              1280,
              720,
            );

            final mappedRect = mapRectToWidget(rect, imageSize, widgetSize);

            return Positioned(
              left: mappedRect.left,
              top: mappedRect.top,
              width: mappedRect.width,
              height: mappedRect.height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
