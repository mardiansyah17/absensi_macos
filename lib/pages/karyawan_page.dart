import 'package:face_client/widgets/app_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Karyawan {
  final String id;
  final String namaLengkap;
  final String departemen;
  final bool wajahTerdaftar;

  const Karyawan({
    required this.id,
    required this.namaLengkap,
    required this.departemen,
    this.wajahTerdaftar = false,
  });

  Karyawan copyWith({
    String? id,
    String? namaLengkap,
    String? departemen,
    bool? wajahTerdaftar,
  }) =>
      Karyawan(
        id: id ?? this.id,
        namaLengkap: namaLengkap ?? this.namaLengkap,
        departemen: departemen ?? this.departemen,
        wajahTerdaftar: wajahTerdaftar ?? this.wajahTerdaftar,
      );
}

class KaryawanPage extends StatefulWidget {
  const KaryawanPage({super.key});

  @override
  State<KaryawanPage> createState() => _KaryawanPageState();
}

class _KaryawanPageState extends State<KaryawanPage> {
  final TextEditingController _search = TextEditingController();

  final List<Karyawan> _data = [
    const Karyawan(
      id: '123ABC',
      namaLengkap: 'Muhammad Mardiansyah',
      departemen: 'DevOps',
      wajahTerdaftar: true,
    ),
  ];

  List<Karyawan> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _data;
    return _data.where((k) {
      return k.id.toLowerCase().contains(q) ||
          k.namaLengkap.toLowerCase().contains(q) ||
          k.departemen.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cari karyawan...',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                AppButton(
                  text: 'Tambah Karyawan',
                  icon: Icons.add,
                  onPressed: _onTambahKaryawan,
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 1100),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: _Header('ID KARYAWAN')),
                          DataColumn(label: _Header('NAMA LENGKAP')),
                          DataColumn(label: _Header('DEPARTEMEN')),
                          DataColumn(label: _Header('STATUS WAJAH')),
                          DataColumn(label: _Header('AKSI')),
                        ],
                        rows: _filtered
                            .map((k) => _buildRow(context, k, cs))
                            .toList(),
                        columnSpacing: 48,
                        horizontalMargin: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Karyawan k, ColorScheme cs) {
    return DataRow(
      cells: [
        DataCell(
            Text(k.id, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(k.namaLengkap)),
        DataCell(Text(k.departemen)),
        DataCell(_StatusChip(terdaftar: k.wajahTerdaftar)),
        DataCell(Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              tooltip: 'Daftarkan/Perbarui Wajah',
              onPressed: () =>
                  _snack('Buka modul pendaftaran wajah untuk ${k.namaLengkap}'),
              icon: Icon(Icons.person_search_rounded, color: cs.primary),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: () => _editKaryawan(k),
              icon: const Icon(Icons.edit_rounded, color: Color(0xFFF59E0B)),
            ),
            IconButton(
              tooltip: 'Hapus',
              onPressed: () => _hapusKaryawan(k),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444)),
            ),
          ],
        )),
      ],
    );
  }

  void _onTambahKaryawan() async {
    final result = await showDialog<Karyawan>(
      context: context,
      builder: (ctx) => EmployeeFormDialog(),
    );
    if (result != null) {
      setState(() => _data.add(result));
      _snack('Karyawan ditambahkan');
    }
  }

  void _editKaryawan(Karyawan k) async {
    final idx = _data.indexOf(k);
    final result = await showDialog<Karyawan>(
      context: context,
      builder: (ctx) => EmployeeFormDialog(),
    );
    if (result != null) {
      setState(() => _data[idx] = result);
      _snack('Perubahan disimpan');
    }
  }

  void _hapusKaryawan(Karyawan k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Karyawan?'),
        content: Text('Data ${k.namaLengkap} akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _data.remove(k));
      _snack('Karyawan dihapus');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.terdaftar});
  final bool terdaftar;

  @override
  Widget build(BuildContext context) {
    if (terdaftar) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF81C784)),
        ),
        child: const Text(
          'Terdaftar',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: const Text(
        'Belum',
        style: TextStyle(
          color: Color(0xFFF57C00),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class EmployeeFormDialog extends StatelessWidget {
  const EmployeeFormDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController idController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    String? selectedDept;

    final List<String> departments = [
      "HRD",
      "Finance",
      "IT",
      "Marketing",
      "Sales",
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Data Karyawan Baru",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Isi detail informasi untuk karyawan yang akan didaftarkan.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Nama
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline),
                hintText: "Nama Lengkap Karyawan",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ID Karyawan
            TextField(
              controller: idController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.tag),
                hintText: "ID Karyawan (NIP)",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Email
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined),
                hintText: "Email",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Departemen
            StatefulBuilder(
              builder: (context, setState) => DropdownButtonFormField<String>(
                value: selectedDept,
                hint: const Text("Pilih Departemen"),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: departments
                    .map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedDept = value);
                },
              ),
            ),

            const SizedBox(height: 20),

            // Tombol
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Tambahkan submit logic disini
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                label: const Text(
                  "Daftarkan Karyawan",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
