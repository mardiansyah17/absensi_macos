import 'package:face_client/core/utils/logger.dart';
import 'package:face_client/datasource/remote_datasource.dart';
import 'package:face_client/models/attendance.dart';
import 'package:face_client/models/employe.dart';
import 'package:face_client/widgets/page_shell.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KehadiranPage extends StatefulWidget {
  const KehadiranPage({super.key});

  @override
  State<KehadiranPage> createState() => _KehadiranPageState();
}

class _KehadiranPageState extends State<KehadiranPage> {
  final RemoteDatasource datasource = RemoteDatasource();
  final List<Attendance> attendances = [];

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    try {
      final data = await datasource.getAttendances();
      setState(() {
        attendances.clear();
        attendances.addAll(data);
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data kehadiran: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              blurRadius: 12,
              spreadRadius: 0,
              offset: Offset(0, 2),
              color: Color(0x14000000))
        ],
      ),
      child: Container(
        width: double.infinity,
        child: DataTable(
          columns: const [
            DataColumn(label: _Header('Nama')),
            DataColumn(label: _Header('DEPARTEMEN')),
            DataColumn(label: _Header('JAM MASUK')),
            DataColumn(label: _Header('JAM KELUAR')),
            DataColumn(label: _Header('STATUS')),
          ],
          rows: attendances.map((e) => _row(e)).toList(),
        ),
      ),
    );
  }

  DataRow _row(Attendance e) {
    return DataRow(cells: [
      DataCell(Text(e.employe.name)),
      DataCell(Text(e.employe.department?.name ?? 'Tidak diketahui')),
      DataCell(Text(e.clockIn?.toLocal().toString() ?? 'Belum masuk')),
      DataCell(Text(e.clockOut?.toLocal().toString() ?? 'Belum keluar')),
      DataCell(Text(e.status)),
    ]);
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w700));
  }
}
