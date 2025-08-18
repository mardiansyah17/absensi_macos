import 'package:face_client/models/employe.dart';
import 'package:face_client/widgets/page_shell.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KehadiranPage extends StatelessWidget {
  const KehadiranPage({super.key});

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
          rows: [],
        ),
      ),
    );
  }

  DataRow _row(Employe e) {
    final hasFace = e.faceImageUrl != null && e.faceImageUrl!.isNotEmpty;
    return DataRow(cells: [
      DataCell(Text(e.nip)),
      DataCell(Text(e.name)),
      DataCell(Text(e.email)),
      DataCell(Text(e.department?.name ?? '-')),
      DataCell(Row(
        children: [
          Icon(hasFace ? Icons.verified : Icons.error_outline,
              size: 18, color: hasFace ? Colors.green : Colors.orange),
          const SizedBox(width: 6),
          Text(hasFace ? 'Terdaftar' : 'Belum Terdaftar',
              style: TextStyle(color: hasFace ? Colors.green : Colors.orange)),
        ],
      )),
      DataCell(Row(
        children: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {},
          ),
        ],
      )),
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
