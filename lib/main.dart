import 'dart:io';

import 'package:face_client/pages/absen_page.dart';
import 'package:face_client/widgets/layout.dart';
import 'package:face_client/widgets/overlay_test.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    WindowOptions windowOptions = const WindowOptions(
      title: "Absensi Athena",
    );
    await WindowManager.instance.setFullScreen(true);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalLoaderOverlay(
      overlayWidgetBuilder: (_) {
        return const GlassOnlyLoaderOverlay(
          lottieAsset: 'assets/animations/loading_face.json',
          scrimOpacity: 0.22,
          blurSigma: 0.5,
          cardOpacity: 0.04,
        );
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Athena HR — Template',
        themeMode: ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF2563EB),
          brightness: Brightness.light,
          visualDensity: VisualDensity.compact,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const Layout(),
      ),
    );
  }
}
