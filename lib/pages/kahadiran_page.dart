import 'package:face_client/widgets/page_shell.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KehadiranPage extends StatelessWidget {
  const KehadiranPage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Kehadiran',
      subtitle: 'Log real‑time & rekap harian',
      actions: [
        OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.arrow_down_doc),
            label: const Text('Export CSV')),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
