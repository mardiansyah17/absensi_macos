import 'package:face_client/widgets/page_shell.dart';
import 'package:face_client/widgets/stat_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Dashboard',
      subtitle: 'Ringkasan cepat aktivitas absensi dan karyawan',
      actions: [
        FilledButton.icon(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.refresh),
            label: const Text('Refresh')),
      ],
      child: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth > 900;
          return GridView.count(
            crossAxisCount: isWide ? 3 : 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: const [
              StatCard(
                  title: 'Hadir Hari Ini',
                  value: '42',
                  hint: '+3 dari kemarin'),
              StatCard(title: 'Terlambat', value: '6', hint: '≤ 15 menit'),
              StatCard(
                  title: 'Izin/Cuti', value: '4', hint: '2 pending approval'),
              StatCard(
                  title: 'Shift Aktif',
                  value: '3',
                  hint: 'Pagi • Siang • Malam'),
              StatCard(
                  title: 'Persentase Hadir', value: '84%', hint: 'Target 90%'),
              StatCard(title: 'Device Online', value: '5/6', hint: '1 offline'),
            ],
          );
        },
      ),
    );
  }
}
