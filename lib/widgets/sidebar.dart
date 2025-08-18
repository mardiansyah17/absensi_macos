import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget? header;
  final List<SidebarSection> sections;
  final Widget? footer;
  final List<Color> accent;

  static const double width = 280;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.header,
    required this.sections,
    this.footer,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (header != null) header!,
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (int s = 0; s < sections.length; s++) ...[
                      _SectionBlock(
                        title: sections[s].title,
                        children: [
                          for (int i = 0; i < sections[s].items.length; i++)
                            _SidebarItemTile(
                              item: sections[s].items[i],
                              selected: selectedIndex == _flatIndex(s, i),
                              onTap: () => onSelect(_flatIndex(s, i)),
                              accent: accent,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (footer != null) ...[
                Divider(
                    color: scheme.outlineVariant.withOpacity(0.6), height: 24),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _flatIndex(int sectionIndex, int itemIndex) {
    int offset = 0;
    for (int i = 0; i < sectionIndex; i++) {
      offset += sections[i].items.length;
    }
    return offset + itemIndex;
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionBlock({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
            child: Text(title.toUpperCase(), style: textStyle),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SidebarItemTile extends StatefulWidget {
  final SidebarItem item;
  final bool selected;
  final VoidCallback onTap;
  final List<Color> accent;
  const _SidebarItemTile(
      {required this.item,
      required this.selected,
      required this.onTap,
      required this.accent});

  @override
  State<_SidebarItemTile> createState() => _SidebarItemTileState();
}

class _SidebarItemTileState extends State<_SidebarItemTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Decoration bgDecor = widget.selected
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: widget.accent,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          )
        : BoxDecoration(
            color: _hover
                ? scheme.surfaceContainerHighest.withOpacity(0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          );

    final Color iconColor = widget.selected
        ? Colors.white
        : Theme.of(context).textTheme.bodyMedium!.color!;
    final TextStyle labelStyle = TextStyle(
      fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
      color: widget.selected
          ? Colors.white
          : Theme.of(context).textTheme.bodyMedium!.color,
    );

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: bgDecor,
      child: Row(
        children: [
          Icon(widget.item.icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text(widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle)),
        ],
      ),
    );

    final content = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: widget.onTap, child: tile),
    );

    return Semantics(
        button: true,
        selected: widget.selected,
        label: widget.item.label,
        child: content);
  }
}

class SidebarSection {
  final String title;
  final List<SidebarItem> items;
  const SidebarSection({required this.title, required this.items});
}

class SidebarItem {
  final IconData icon;
  final String label;
  final int? badgeCount;
  const SidebarItem({required this.icon, required this.label, this.badgeCount});
}
