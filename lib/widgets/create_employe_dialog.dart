import 'package:face_client/core/utils/logger.dart';
import 'package:face_client/datasource/remote_datasource.dart';
import 'package:face_client/models/department.dart';
import 'package:face_client/models/employe.dart';
import 'package:face_client/widgets/glass_card.dart';
import 'package:face_client/widgets/primary_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateEmployeeDialog extends StatefulWidget {
  final List<Department> departments;
  final Function? onRefresh;
  const CreateEmployeeDialog({
    super.key,
    required this.departments,
    this.onRefresh,
  });
  @override
  State<CreateEmployeeDialog> createState() => CreateEmployeeDialogState();
}

class CreateEmployeeDialogState extends State<CreateEmployeeDialog> {
  late final TextEditingController _name = TextEditingController();
  late final TextEditingController _code = TextEditingController();
  late final TextEditingController _email = TextEditingController();
  String? _department;

  @override
  void initState() {
    super.initState();
  }

  void _onSave() async {
    final name = _name.text.trim();
    final code = _code.text.trim();
    final email = _email.text.trim();

    try {
      final newEmp = Employe(
        id: '',
        name: name,
        nip: code,
        email: email,
        department: widget.departments.firstWhere((d) => d.id == _department),
      );
      await RemoteDatasource().registerEmploye(newEmp);
      Navigator.pop(context, newEmp);
    } catch (e) {
      logger.e('Gagal menyimpan karyawan: $e');
    } finally {
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
      _name.clear();
      _code.clear();
      _email.clear();
      setState(() {
        _department = null;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(CupertinoIcons.add, size: 18),
                const SizedBox(width: 8),
                const Text('Tambah Karyawan',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(CupertinoIcons.xmark_circle_fill, size: 20)),
              ]),
              const SizedBox(height: 12),
              TextField(
                  controller: _name,
                  decoration: _inputDecoration().copyWith(labelText: 'Nama')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _department,
                items: [
                  for (final d in widget.departments)
                    DropdownMenuItem<String?>(value: d.id, child: Text(d.name))
                ],
                onChanged: (v) => setState(() => _department = v),
                decoration:
                    _inputDecoration().copyWith(labelText: 'Departemen'),
                icon: const Icon(CupertinoIcons.chevron_down, size: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: _code,
                  decoration: _inputDecoration().copyWith(labelText: 'Kode')),
              const SizedBox(height: 12),
              TextField(
                  controller: _email,
                  decoration: _inputDecoration().copyWith(labelText: 'Email')),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                const SizedBox(width: 8),
                PrimaryButton(
                  icon: CupertinoIcons.check_mark,
                  label: 'Simpan',
                  onPressed: () {
                    _onSave();
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.2),
        ),
      );
}
