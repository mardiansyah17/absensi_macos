import 'package:camera/camera.dart';
import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_view.dart';
import 'package:flutter/material.dart';

class CameraWidget extends StatefulWidget {
  final GlobalKey cameraKey;
  final Function(CameraMacOSController) onCameraInizialized;

  const CameraWidget({
    super.key,
    required this.cameraKey,
    required this.onCameraInizialized,
  });

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0,
      child: CameraMacOSView(
        key: widget.cameraKey,
        enableAudio: false,
        cameraMode: CameraMacOSMode.photo,
        fit: BoxFit.cover,
        onCameraInizialized: widget.onCameraInizialized,
      ),
    );
  }
}
