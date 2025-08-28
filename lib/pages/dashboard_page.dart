import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardData {
  final int employees;
  final int presentToday;
  final int alphaToday;
  final List<String> weekLabels;
  final List<int> weekPresent;
  final double percentPresent;

  DashboardData({
    required this.employees,
    required this.presentToday,
    required this.alphaToday,
    required this.weekLabels,
    required this.weekPresent,
    required this.percentPresent,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] ?? {};
    final today = json['today'] ?? {};
    final week = json['week'] ?? {};
    final donut = json['donut'] ?? {};

    final labels =
        (week['labels'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final present =
        (week['present'] as List?)?.map((e) => (e as num).toInt()).toList() ??
            const <int>[];

    double pct = (donut['percentPresent'] as num?)?.toDouble() ?? 0;

    final p = (today['present'] as num?)?.toInt() ?? 0;
    final a = (today['alpha'] as num?)?.toInt() ?? 0;
    if (pct == 0 && (p + a) > 0) pct = (p / (p + a)) * 100.0;

    return DashboardData(
      employees: (totals['employees'] as num?)?.toInt() ?? 0,
      presentToday: p,
      alphaToday: a,
      weekLabels: labels,
      weekPresent: present,
      percentPresent: pct,
    );
  }
}

class DashboardApi {
  final Dio dio;
  final String baseUrl;

  DashboardApi(this.dio, {required this.baseUrl});

  Future<DashboardData> fetch({DateTime? anchor}) async {
    final dateStr =
        (anchor ?? DateTime.now()).toIso8601String().substring(0, 10);
    final res = await dio
        .get('$baseUrl/dashboard', queryParameters: {'date': "2025-08-01"});
    return DashboardData.fromJson(res.data as Map<String, dynamic>);
  }
}

class DashboardVM extends ChangeNotifier {
  final DashboardApi api;
  DashboardVM(this.api);

  DashboardData? data;
  String? error;
  bool loading = false;
  int range = 7;
  DateTime anchor = DateTime.now();

  Future<void> init() async {
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await api.fetch(anchor: anchor);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setRange(int r) {
    range = r;

    anchor = DateTime.now();
    refresh();
  }
}

/* ======================= UI ======================= */

class DashboardPageMacOS extends StatefulWidget {
  const DashboardPageMacOS({super.key});

  @override
  State<DashboardPageMacOS> createState() => _DashboardPageMacOSState();
}

class _DashboardPageMacOSState extends State<DashboardPageMacOS> {
  late final DashboardVM vm;

  static const BASE_URL = 'http://localhost:8001/api';

  @override
  void initState() {
    super.initState();
    final dio = Dio(BaseOptions(
      baseUrl: BASE_URL,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ));
    vm = DashboardVM(DashboardApi(dio, baseUrl: BASE_URL));
    vm.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            _GlassToolbar(
              title: 'Dashboard',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  _GlassIconButton(icon: Icons.refresh, onPressed: vm.refresh),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: vm,
                builder: (context, _) {
                  if (vm.loading && vm.data == null) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  if (vm.error != null) {
                    return _ErrorState(message: vm.error!, onRetry: vm.refresh);
                  }
                  final d = vm.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                        const SizedBox(height: 20),
                        _kpiGrid(context, d),
                        const SizedBox(height: 20),
                        _chartsRow(context, d),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------- Sections ---------- */

  Widget _kpiGrid(BuildContext context, DashboardData d) {
    final items = [
      _KpiCard(
        label: 'Total Karyawan',
        value: d.employees.toString(),
        color: const Color(0xFF2563EB),
        icon: Icons.people_alt_rounded,
        sparkline: const [80, 82, 83, 84, 85, 86, 88],
      ),
      _KpiCard(
        label: 'Hadir Hari Ini',
        value: d.presentToday.toString(),
        color: const Color(0xFF16A34A),
        icon: Icons.verified_rounded,
        sparkline: const [90, 92, 94, 96, 97, 98, 99],
      ),
      _KpiCard(
        label: 'Alpha',
        value: d.alphaToday.toString(),
        color: const Color(0xFFEF4444),
        icon: Icons.cancel_rounded,
        sparkline: const [12, 11, 10, 9, 9, 8, 7],
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        int columns = 3;
        if (w < 1200) columns = 2;
        if (w < 730) columns = 1;

        const gap = 16.0;
        final itemWidth = (w - gap * (columns - 1)) / columns;
        final targetHeight = w < 730 ? 140.0 : 130.0;
        final ratio = itemWidth / targetHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: ratio,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => items[i],
        );
      },
    );
  }

  Widget _chartsRow(BuildContext context, DashboardData d) {
    return LayoutBuilder(builder: (context, c) {
      final narrow = c.maxWidth < 1100;
      final chartHeight = narrow ? 280.0 : 320.0;
      final donutRadius = chartHeight * 0.25;
      final donutCenter = chartHeight * 0.18;

      final kiri = _GlassCard(
        title: 'Kehadiran Mingguan',
        subtitle: 'Sen – Jum',
        child: SizedBox(
          height: chartHeight,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: (d.weekPresent.isEmpty
                      ? 0
                      : (d.weekPresent.reduce((a, b) => a > b ? a : b) + 8))
                  .toDouble(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (g, gi, r, ri) {
                    final days = d.weekLabels.isEmpty
                        ? const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum']
                        : d.weekLabels;
                    return BarTooltipItem(
                      '${days[g.x.toInt()]}: ${r.toY.toInt()} hadir',
                      const TextStyle(fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.black.withOpacity(0.06), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 20,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final days = d.weekLabels.isEmpty
                          ? const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum']
                          : d.weekLabels;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          days[v.toInt()],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(d.weekPresent.length, (i) {
                final val = d.weekPresent[i].toDouble();
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: val,
                      width: 22,
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      );

      final kanan = _GlassCard(
        title: 'Status Karyawan',
        subtitle: 'Hari ini',
        child: SizedBox(
          height: chartHeight,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: donutCenter,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                              value: d.presentToday.toDouble(),
                              color: const Color(0xFF22C55E),
                              radius: donutRadius),
                          PieChartSectionData(
                              value: d.alphaToday.toDouble(),
                              color: const Color(0xFFEF4444),
                              radius: donutRadius),
                        ],
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${d.percentPresent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text('Hadir',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: Color(0xFF22C55E), label: 'Hadir'),
                  SizedBox(width: 12),
                  _LegendDot(color: Color(0xFFEF4444), label: 'Alpha'),
                ],
              ),
            ],
          ),
        ),
      );

      if (narrow) {
        return Column(children: [kiri, const SizedBox(height: 16), kanan]);
      } else {
        return Row(children: [
          Expanded(flex: 2, child: kiri),
          const SizedBox(width: 16),
          Expanded(child: kanan)
        ]);
      }
    });
  }
}

/* ======================= PIECES (UI components) ======================= */

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 36, color: Color(0xFF64748B)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _GlassToolbar extends StatelessWidget {
  const _GlassToolbar({required this.title, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            border: const Border(bottom: BorderSide(color: Color(0x1A000000))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            const Icon(Icons.dashboard_rounded,
                color: Color(0xFF3B82F6), size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
          ]),
        ),
      ),
    );
  }
}

class _RangeControl extends StatelessWidget {
  const _RangeControl({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<int>(
      groupValue: value,
      padding: const EdgeInsets.all(4),
      backgroundColor: const Color(0xFFE5E7EB),
      children: const {
        1: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text('Today')),
        7: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text('Week')),
        30: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text('Month')),
      },
      onValueChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.6),
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 38,
              width: 38,
              child: Icon(icon, size: 18, color: const Color(0xFF111827)),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.sparkline,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final List<int> sparkline;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      title: label,
      trailing: Icon(icon, color: color, size: 20),
      titleColor: const Color(0xFF64748B),
      child: Row(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
              duration: const Duration(milliseconds: 700),
              builder: (_, v, __) => Text(
                v.toInt().toString(),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1,
                    ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            height: 40,
            child: LineChart(
              LineChartData(
                minY: sparkline.reduce((a, b) => a < b ? a : b).toDouble() - 2,
                maxY: sparkline.reduce((a, b) => a > b ? a : b).toDouble() + 2,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.22),
                          color.withOpacity(0.02)
                        ],
                      ),
                    ),
                    gradient:
                        LinearGradient(colors: [color, color.withOpacity(0.6)]),
                    spots: List.generate(sparkline.length,
                        (i) => FlSpot(i.toDouble(), sparkline[i].toDouble())),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatefulWidget {
  const _GlassCard({
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final EdgeInsets padding;
  @override
  State<_GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<_GlassCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hover ? 0.08 : 0.05),
              blurRadius: _hover ? 20 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                border: Border.all(color: Colors.white.withOpacity(0.6)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title != null)
                    Row(children: [
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: widget.titleColor ??
                                      const Color(0xFF0F172A),
                                ),
                          ),
                          if (widget.subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(widget.subtitle!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B))),
                            ),
                        ],
                      )),
                      if (widget.trailing != null) widget.trailing!,
                    ]),
                  if (widget.title != null) const SizedBox(height: 14),
                  widget.child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
    ]);
  }
}
