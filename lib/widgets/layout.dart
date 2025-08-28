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
    SidebarItem(icon: CupertinoIcons.calendar, label: 'Karyawan'),
  ];

  static const List<Color> _accent = [
    Color(0xFF3B82F6),
    Color(0xFF60A5FA),
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardPageMacOS(),
      const KahadiranPage(),
      const EmployeesPageMacOSV2(),
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
            sections: [
              SidebarSection(title: 'Utama', items: _itemsMain),
            ],
            accent: _accent,
          ),
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
