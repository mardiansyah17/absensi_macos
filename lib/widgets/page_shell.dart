import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PageShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions; // tombol di kanan atas
  final Widget child;

  const PageShell({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar sederhana
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.6))),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(subtitle!,
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.black54)),
                      ),
                  ],
                ),
                const Spacer(),
                if (actions != null) ...actions!,
              ],
            ),
          ),

          // Konten
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
