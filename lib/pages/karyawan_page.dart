import 'dart:async';
import 'dart:ui';
import 'package:face_client/datasource/remote_datasource.dart';
import 'package:face_client/models/department.dart';
import 'package:face_client/models/employe.dart';
import 'package:face_client/services/to_csv.dart';
import 'package:face_client/widgets/create_employe_dialog.dart';
import 'package:face_client/widgets/edit_employe_dialog.dart';
import 'package:face_client/widgets/glass_card.dart';
import 'package:face_client/widgets/primary_button.dart';
import 'package:face_client/widgets/register_face_dialog_macos.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:to_csv/to_csv.dart' as exportCSV;

class EmployeesPageMacOSV2 extends StatefulWidget {
  const EmployeesPageMacOSV2({super.key});

  @override
  State<EmployeesPageMacOSV2> createState() => _EmployeesPageMacOSV2State();
}

class _EmployeesPageMacOSV2State extends State<EmployeesPageMacOSV2> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final RemoteDatasource _datasource = RemoteDatasource();

  List<Department> _departments = [];

  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    getEmployes();
    getDepartements();
  }

  void getDepartements() async {
    final departments = await _datasource.getDepartements();
    setState(() {
      _departments = departments;
    });
  }

  void getEmployes() async {
    context.loaderOverlay.show();
    final employees = await _datasource.getEmployes();
    final mapped = employees
        .map((e) => Employe(
              id: e.id,
              name: e.name,
              department: e.department,
              nip: e.nip,
              faceImageUrl: e.faceImageUrl,
              email: e.email,
            ))
        .toList();
    setState(() {
      _employees = mapped;
      _loading = false;
    });
    context.loaderOverlay.hide();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF):
            const _FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
            const _NewIntent(),
      },
      child: Actions(
        actions: {
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(onInvoke: (_) {
            FocusScope.of(context).requestFocus(_searchFocus);
            return null;
          }),
          _NewIntent: CallbackAction<_NewIntent>(onInvoke: (_) {
            _onAdd();
            return null;
          }),
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          body: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEAF2FF), Color(0xFFFFFFFF)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _GlassToolbar(child: _buildToolbar(context)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context),
                              const SizedBox(height: 16),
                              _buildStats(context),
                              const SizedBox(height: 16),
                              if (_loading)
                                const _SkeletonTable()
                              else
                                _buildTableCard(context),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        const Icon(CupertinoIcons.person_2, size: 18),
        const SizedBox(width: 8),
        Text(
          'Karyawan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.8),
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        _MacTextField(
          focusNode: _searchFocus,
          controller: _searchCtrl,
          hintText: 'Cari nama / departemen / kode… (⌘F)',
          width: 300,
        ),
        const SizedBox(width: 12),
        _GhostButton(
          icon: LucideIcons.download,
          label: 'Export',
          onPressed: () async {
            final header = [
              'Nama',
              'Departemen',
              'NIP',
            ];
            final listOfLists = _employees.map((e) {
              return [
                e.name,
                e.department?.name ?? ' - ',
                e.nip,
              ];
            }).toList();

            try {
              final savedPath = await saveCsvWithDialogOrFallback(
                header: header,
                rows: listOfLists,
                suggestedFileName: 'absensi.csv',
              );

              await revealInFinder(savedPath);

              print('File tersimpan: $savedPath');
            } catch (e) {
              print('Gagal menyimpan: $e');
            }
          },
        ),
        const SizedBox(width: 8),
        PrimaryButton(
          icon: LucideIcons.userPlus,
          label: 'Tambah (⌘N)',
          onPressed: _onAdd,
        ),
      ],
    );
  }

  void _onAdd() async {
    await showDialog<Employe>(
      context: context,
      builder: (_) => CreateEmployeeDialog(
        departments: _departments,
        onRefresh: () {
          getEmployes();
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daftar Karyawan',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2)),
              const SizedBox(height: 6),
              Text(
                'Kelola data karyawan, status akun, dan pendaftaran wajah untuk absensi.',
                style: TextStyle(
                    fontSize: 13, color: Colors.black.withOpacity(0.55)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final k = _calcKpis(_employees);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StatCard(
            title: 'Total', value: '${k.total}', icon: CupertinoIcons.person_3),
        _StatCard(
            title: 'Terdaftar Wajah',
            value: '${k.withFace}',
            icon: CupertinoIcons.flag),
        _StatCard(
            title: 'Belum Daftar Wajah',
            value: '${k.withoutFace}',
            icon: CupertinoIcons.exclamationmark_triangle),
      ],
    );
  }

  Widget _buildTableCard(BuildContext context) {
    final pageRows = _employees;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.table_badge_more, size: 18),
              SizedBox(width: 8),
              Text('Karyawan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _EmployeesTable(
                rows: pageRows,
                onEdit: (row) async {
                  await showDialog<Employe>(
                    context: context,
                    builder: (_) => EditEmployeDialog(
                      onRefresh: () {
                        getEmployes();
                      },
                      departments: _departments,
                      employe: Employe(
                        id: row.id,
                        name: row.name,
                        nip: row.nip,
                        email: row.email,
                        department: row.department,
                      ),
                    ),
                  );
                },
                onDelete: (row) async {},
                onRegisterFace: (row) async {
                  showDialog(
                    context: context,
                    builder: (_) => RegisterFaceDialogMacOS(
                      employeeId: row.id,
                      existingFaceUrl: row.faceImageUrl,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmployeesTable extends StatelessWidget {
  const _EmployeesTable({
    required this.rows,
    required this.onEdit,
    required this.onDelete,
    required this.onRegisterFace,
  });

  final List<Employe> rows;

  final void Function(Employe row) onEdit;
  final void Function(Employe row) onDelete;
  final void Function(Employe row) onRegisterFace;

  @override
  Widget build(BuildContext context) {
    final table = DataTable(
      headingTextStyle:
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      dataTextStyle: const TextStyle(fontSize: 13),
      headingRowColor: WidgetStatePropertyAll(Colors.white.withOpacity(0.8)),
      columns: const [
        DataColumn(label: Text('Nama')),
        DataColumn(
          label: Text('Departemen'),
        ),
        DataColumn(
          label: Text('Kode'),
        ),
        DataColumn(label: Text('Wajah')),
        DataColumn(label: Text('Aksi')),
      ],
      rows: [
        for (final r in rows)
          DataRow(
            color: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFFEFF6FF);
              }
              if (states.contains(WidgetState.hovered)) {
                return Colors.black.withOpacity(0.02);
              }
              return null;
            }),
            cells: [
              DataCell(Row(children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                  backgroundImage:
                      (r.faceImageUrl != null && r.faceImageUrl!.isNotEmpty)
                          ? NetworkImage(r.faceImageUrl!)
                          : null,
                  child: (r.faceImageUrl == null || r.faceImageUrl!.isEmpty)
                      ? Text(r.name.isNotEmpty ? r.name[0] : '?')
                      : null,
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(r.name, overflow: TextOverflow.ellipsis)),
              ])),
              DataCell(Text(r.department?.name ?? ' -')),
              DataCell(Text(r.nip)),
              DataCell(Row(children: [
                Icon(
                    r.faceImageUrl != null && r.faceImageUrl!.isNotEmpty
                        ? CupertinoIcons.checkmark_seal
                        : CupertinoIcons.exclamationmark_triangle,
                    size: 16,
                    color: r.faceImageUrl != null && r.faceImageUrl!.isNotEmpty
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFB45309)),
                const SizedBox(width: 6),
                Text(r.faceImageUrl != null ? 'Terdaftar' : 'Belum'),
              ])),
              DataCell(Row(children: [
                _IconAction(
                    tooltip: 'Edit',
                    icon: LucideIcons.pencil,
                    onTap: () => onEdit(r)),
                _IconAction(
                    tooltip: 'Daftarkan Wajah',
                    icon: LucideIcons.camera,
                    onTap: () => onRegisterFace(r)),
                _IconAction(
                    tooltip: 'Hapus',
                    icon: LucideIcons.trash,
                    danger: true,
                    onTap: () => onDelete(r)),
              ])),
            ],
          )
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double parentWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: parentWidth),
            child: table,
          ),
        );
      },
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction(
      {required this.tooltip,
      required this.icon,
      required this.onTap,
      this.danger = false});
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: danger ? const Color(0xFFFFEEF0) : Colors.white,
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Icon(icon,
                size: 16,
                color: danger ? const Color(0xFFB91C1C) : Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _GlassToolbar extends StatelessWidget {
  const _GlassToolbar({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            border: Border(
                bottom: BorderSide(color: Colors.black.withOpacity(0.06))),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton(
      {required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.black.withOpacity(0.12)),
        foregroundColor: Colors.black.withOpacity(0.85),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Colors.black.withOpacity(0.65), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration() => InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class _MacTextField extends StatelessWidget {
  const _MacTextField(
      {required this.controller,
      required this.hintText,
      this.onSubmitted,
      this.width,
      this.focusNode});
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onSubmitted;
  final double? width;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) {
    final field = TextField(
      focusNode: focusNode,
      controller: controller,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: _inputDecoration().copyWith(
        hintText: hintText,
        prefixIcon: const Icon(CupertinoIcons.search, size: 18),
      ),
    );
    return width != null ? SizedBox(width: width, child: field) : field;
  }
}

class _AccountStatusTag extends StatelessWidget {
  const _AccountStatusTag({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final bool active = status == 'Aktif';
    final bg = active ? const Color(0xFFEFFBF5) : const Color(0xFFFFEEF0);
    final fg = active ? const Color(0xFF047857) : const Color(0xFFB91C1C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
      child: Text(status,
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.total,
    required this.rowsPerPage,
    required this.page,
    required this.onRowsPerPageChanged,
    required this.onPageChanged,
  });
  final int total;
  final int rowsPerPage;
  final int page;
  final ValueChanged<int> onRowsPerPageChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / rowsPerPage).ceil().clamp(1, 9999);
    final canPrev = page > 0;
    final canNext = page < totalPages - 1;

    return Row(
      children: [
        Text(
            'Menampilkan ${(page * rowsPerPage) + 1}–${((page + 1) * rowsPerPage).clamp(0, total)} dari $total',
            style:
                TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6))),
        const Spacer(),
        DropdownButton<int>(
          value: rowsPerPage,
          items: const [10, 20, 50]
              .map((e) => DropdownMenuItem(value: e, child: Text('$e/hal')))
              .toList(),
          onChanged: (v) => onRowsPerPageChanged(v ?? rowsPerPage),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Sebelumnya',
          onPressed: canPrev ? () => onPageChanged(page - 1) : null,
          icon: const Icon(CupertinoIcons.chevron_left),
        ),
        IconButton(
          tooltip: 'Berikutnya',
          onPressed: canNext ? () => onPageChanged(page + 1) : null,
          icon: const Icon(CupertinoIcons.chevron_right),
        ),
      ],
    );
  }
}

class _SkeletonTable extends StatelessWidget {
  const _SkeletonTable();
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(6, (i) => _skeletonRow())
            .expand((w) => [w, const SizedBox(height: 8)])
            .toList(),
      ),
    );
  }

  Widget _skeletonRow() {
    return Row(children: [
      _skel(220),
      const SizedBox(width: 12),
      _skel(140),
      const SizedBox(width: 12),
      _skel(80),
      const SizedBox(width: 12),
      _skel(80),
      const SizedBox(width: 12),
      _skel(120),
    ]);
  }

  Widget _skel(double w) => Container(
      height: 22,
      width: w,
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8)));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.06))),
      child: Column(children: [
        const Icon(CupertinoIcons.person_crop_circle_badge_exclam, size: 36),
        const SizedBox(height: 8),
        Text('Tidak ada data',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.9))),
        const SizedBox(height: 6),
        Text('Coba ubah pencarian atau filter.',
            style:
                TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6))),
      ]),
    );
  }
}

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool> _confirm(BuildContext context, String msg) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Konfirmasi'),
      content: Text(msg),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya')),
      ],
    ),
  );
  return yes == true;
}

class _EmpKpis {
  final int total;
  final int withFace;
  final int withoutFace;
  const _EmpKpis(this.total, this.withFace, this.withoutFace);
}

_EmpKpis _calcKpis(List<Employe> rows) {
  final total = rows.length;
  final withFace = rows.where((e) => e.faceImageUrl != null).length;
  final withoutFace = total - withFace;
  return _EmpKpis(total, withFace, withoutFace);
}

List<Employe> _employees = [];

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _NewIntent extends Intent {
  const _NewIntent();
}
