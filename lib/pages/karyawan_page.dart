import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/camera_macos_view.dart';
import 'package:dio/dio.dart';
import 'package:face_client/widgets/register_face_dialog_macos.dart';
import 'package:flutter/material.dart';

import 'package:face_client/core/utils/logger.dart';
import 'package:face_client/datasource/remote_datasource.dart';
import 'package:face_client/models/department.dart';
import 'package:face_client/models/employe.dart';
import 'package:face_client/widgets/app_button.dart';
import 'package:path_provider/path_provider.dart';

class KaryawanPage extends StatefulWidget {
  const KaryawanPage({super.key});

  @override
  State<KaryawanPage> createState() => _KaryawanPageState();
}

class _KaryawanPageState extends State<KaryawanPage> {
  final _remote = RemoteDatasource();

  final List<Employe> _items = [];
  final List<Department> _departments = [];

  final TextEditingController _searchCtrl = TextEditingController();
  final ValueNotifier<bool> _loading = ValueNotifier<bool>(true);
  final ValueNotifier<String> _query = ValueNotifier<String>('');
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _bootstrap() async {
    _loading.value = true;
    try {
      final results = await Future.wait([
        _remote.getEmployes(),
        _remote.getDepartements(),
      ]);

      final employees = _asEmployeList(results[0]);
      final depts = _asDepartmentList(results[1]);

      _items
        ..clear()
        ..addAll(employees);
      _departments
        ..clear()
        ..addAll(depts);
    } catch (e, st) {
      logger.e('Gagal memuat data', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      _loading.value = false;
      if (mounted) setState(() {});
    }
  }

  // ---------------- Mapper defensif ------------------
  List<Department> _asDepartmentList(dynamic raw) {
    if (raw is List<Department>) return raw;
    if (raw is List) {
      return raw.map<Department>((e) {
        if (e is Department) return e;
        if (e is Map<String, dynamic>) return Department.fromJson(e);
        if (e is Map) return Department.fromJson(e.cast<String, dynamic>());
        // Fallback jika server hanya kirim string nama departemen
        if (e is String) return Department(id: e, name: e);
        throw StateError('Item bukan Department yang valid: $e');
      }).toList();
    }
    return const [];
  }

  List<Employe> _asEmployeList(dynamic raw) {
    if (raw is List<Employe>) return raw;
    if (raw is List) {
      return raw
          .map<Employe>((e) {
            try {
              if (e is Employe) return e;
              if (e is Map<String, dynamic>) {
                final m = e;
                Department? dept;
                final d = m['department'];
                if (d is Map<String, dynamic>) {
                  dept = Department.fromJson(d);
                } else if (d is Map) {
                  dept = Department.fromJson(d.cast<String, dynamic>());
                } else if (d is String && d.isNotEmpty) {
                  dept = Department(id: d, name: d);
                }
                return Employe(
                  id: (m['id'] ?? '').toString(),
                  name: (m['name'] ?? '').toString(),
                  nip: (m['nip'] ?? '').toString(),
                  email: (m['email'] ?? '').toString(),
                  department: dept,
                  faceImageUrl: m['faceImageUrl']?.toString(),
                );
              }
              if (e is Map) {
                final m = e.cast<String, dynamic>();
                Department? dept;
                final d = m['department'];
                if (d is Map<String, dynamic>) {
                  dept = Department.fromJson(d);
                } else if (d is Map) {
                  dept = Department.fromJson(d.cast<String, dynamic>());
                } else if (d is String && d.isNotEmpty) {
                  dept = Department(id: d, name: d);
                }
                return Employe(
                  id: (m['id'] ?? '').toString(),
                  name: (m['name'] ?? '').toString(),
                  nip: (m['nip'] ?? '').toString(),
                  email: (m['email'] ?? '').toString(),
                  department: dept,
                  faceImageUrl: m['faceImageUrl']?.toString(),
                );
              }
              throw StateError('Item bukan Employe yang valid: $e');
            } catch (e) {
              // Jika struktur tidak sesuai, buang dengan aman
              logger.w('Lewati item tidak valid saat parsing Employe: $e');
              return Employe(
                id: '',
                name: '',
                nip: '',
                email: '',
              );
            }
          })
          .where((e) => e.id.isNotEmpty)
          .toList();
    }
    return const [];
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _query.value = _searchCtrl.text.trim().toLowerCase();
    });
  }

  List<Employe> _applyFilter(String q) {
    if (q.isEmpty) return _items;
    return _items.where((e) {
      final dpt = e.department?.name ?? '';
      final face = (e.faceImageUrl != null && e.faceImageUrl!.isNotEmpty)
          ? 'terdaftar'
          : 'belum';
      return e.name.toLowerCase().contains(q) ||
          e.id.toLowerCase().contains(q) ||
          e.nip.toLowerCase().contains(q) ||
          e.email.toLowerCase().contains(q) ||
          dpt.toLowerCase().contains(q) ||
          face.contains(q);
    }).toList();
  }

  Future<void> _deleteEmploye(Employe emp) async {
    showDialog(
      context: context,
      builder: (_) => RegisterFaceDialogMacOS(
        employeeId: emp.id, // ID karyawan
        existingFaceUrl: emp.faceImageUrl,
      ),
    );
  }

  Future<void> _openEditDialog({Employe? initial}) async {
    final result = await showDialog<Employe>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _KaryawanFormDialog(
        initial: initial,
        departments: _departments,
      ),
    );

    if (result == null) return;

    final isUpdate = initial != null;
    try {
      await _bootstrap(); // Re-fetch data setelah tambah/update
      if (mounted) setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(isUpdate ? 'Perubahan disimpan' : 'Karyawan ditambahkan')),
      );
    } catch (e, st) {
      logger.e('Simpan gagal', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _loading.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText:
                            'Cari (ID/Nama/NIP/Email/Departemen/Status wajah)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () {
                      _bootstrap();
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 12),
                  AppButton.primary(
                    onPressed: () => _openEditDialog(),
                    icon:
                        const Icon(Icons.person_add_alt_1, color: Colors.white),
                    label: const Text('Tambah Karyawan',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _loading,
                  builder: (_, isLoading, __) {
                    if (isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ValueListenableBuilder<String>(
                      valueListenable: _query,
                      builder: (_, q, __) {
                        final filtered = _applyFilter(q);
                        if (filtered.isEmpty) {
                          return const Center(child: Text('Tidak ada data'));
                        }
                        return _KaryawanTable(
                          data: filtered,
                          onEdit: (e) => _openEditDialog(initial: e),
                          onDelete: _deleteEmploye,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KaryawanTable extends StatelessWidget {
  const _KaryawanTable({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Employe> data;
  final ValueChanged<Employe> onEdit;
  final ValueChanged<Employe> onDelete;

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
            DataColumn(label: _Header('NIP')),
            DataColumn(label: _Header('Nama')),
            DataColumn(label: _Header('Email')),
            DataColumn(label: _Header('Departemen')),
            DataColumn(label: _Header('Status Wajah')),
            DataColumn(label: _Header('Aksi')),
          ],
          rows: data.map(_row).toList(),
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
            onPressed: () => onEdit(e),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => onDelete(e),
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

/// Dialog Form Tambah/Edit Karyawan
class _KaryawanFormDialog extends StatefulWidget {
  const _KaryawanFormDialog({
    required this.departments,
    this.initial,
  });

  final List<Department> departments;
  final Employe? initial;

  @override
  State<_KaryawanFormDialog> createState() => _KaryawanFormDialogState();
}

class _KaryawanFormDialogState extends State<_KaryawanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nipCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _faceUrlCtrl = TextEditingController();
  String? _selectedDeptId;

  bool _saving = false;

  final _remote = RemoteDatasource();

  bool get isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _idCtrl.text = init.id;
      _nameCtrl.text = init.name;
      _nipCtrl.text = init.nip;
      _emailCtrl.text = init.email;
      _faceUrlCtrl.text = init.faceImageUrl ?? '';
      _selectedDeptId = init.department?.id;
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _nipCtrl.dispose();
    _emailCtrl.dispose();
    _faceUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(isEdit ? 'Edit Karyawan' : 'Tambah Karyawan'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nipCtrl,
                decoration: const InputDecoration(
                  labelText: 'NIP',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedDeptId,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('- Pilih Departemen -'),
                  ),
                  ...widget.departments.map((d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.name),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedDeptId = v),
                decoration: const InputDecoration(
                  labelText: 'Departemen',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _faceUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL Foto Wajah (opsional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        AppButton.primary(
          onPressed: _saving ? null : _submit,
          label: Text(_saving
              ? 'Menyimpan...'
              : (isEdit ? 'Simpan Perubahan' : 'Tambah')),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    Department? selDept;
    for (final d in widget.departments) {
      if (d.id == _selectedDeptId) {
        selDept = d;
        break;
      }
    }

    final emp = Employe(
      id: _idCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      nip: _nipCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      department: selDept,
      faceImageUrl:
          _faceUrlCtrl.text.trim().isEmpty ? null : _faceUrlCtrl.text.trim(),
    );
    if (widget.initial != null) {
      // Update existing employe
      try {
        await _remote.updateEmploye(emp.id, {
          'name': emp.name,
          'nip': emp.nip,
          'email': emp.email,
          'departmentId': emp.department?.id,
        });
        Navigator.of(context).pop(emp);
      } catch (e, st) {
        logger.e('Update gagal', error: e, stackTrace: st);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $e')),
        );
      }
    } else {
      // Create new employe
      try {
        await _remote.registerEmploye(emp);
        Navigator.of(context).pop(emp);
      } catch (e, st) {
        logger.e('Tambah gagal', error: e, stackTrace: st);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan: $e')),
        );
      }
    }
    setState(() => _saving = false);
  }
}
