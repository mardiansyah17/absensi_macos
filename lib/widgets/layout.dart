import 'package:face_client/pages/dashboard_page.dart';
import 'package:face_client/pages/kahadiran_page.dart';
import 'package:face_client/pages/karyawan_page.dart';
import 'package:face_client/widgets/sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lazy_indexed_stack/flutter_lazy_indexed_stack.dart';

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  int _selectedIndex = 2;

  final List<SidebarItem> _itemsMain = const [
    SidebarItem(icon: CupertinoIcons.square_grid_2x2, label: 'Dashboard'),
    SidebarItem(
        icon: CupertinoIcons.check_mark_circled,
        label: 'Kehadiran',
        badgeCount: 2),
    SidebarItem(icon: CupertinoIcons.person_2, label: 'Karyawan'),
    SidebarItem(icon: CupertinoIcons.calendar, label: 'Jadwal'),
    SidebarItem(icon: CupertinoIcons.doc_text, label: 'Laporan'),
  ];

  final List<SidebarItem> _itemsOther = const [
    SidebarItem(icon: CupertinoIcons.briefcase, label: 'Cuti'),
    SidebarItem(icon: CupertinoIcons.gear_alt_fill, label: 'Pengaturan'),
  ];

  // Biru gradient untuk state aktif
  static const List<Color> _accent = [
    Color(0xFF3B82F6), // Blue 500
    Color(0xFF60A5FA), // Blue 400
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      DashboardPage(),
      KehadiranPage(),
      KaryawanPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
            // header: const _BrandHeader(),
            sections: [
              SidebarSection(title: 'Utama', items: _itemsMain),
              SidebarSection(title: 'Lainnya', items: _itemsOther),
            ],

            accent: _accent,
          ),

          // Main area — gunakan IndexedStack agar state halaman tetap terjaga
          Expanded(
            child: LazyIndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}
