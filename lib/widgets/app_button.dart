import 'package:flutter/material.dart';

/// AppButton – tombol modern untuk desktop/macOS & mobile
/// Fitur:
/// - Variants: primary, tonal, outline
/// - State: hover, pressed, focused (animated)
/// - Disabled & loading
/// - Ukuran: small, medium, large
/// - Aksesibilitas: keyboard (Enter/Space), semantics, tooltip
/// - Backward-compatible dengan versi lama (punya `text` & `icon: IconData?`)
class AppButton extends StatefulWidget {
  /// Backward-compatible: gunakan `text` + `icon: IconData?` seperti versi lama
  /// atau gunakan `label` (Widget) + `iconWidget` (Widget) untuk kontrol penuh.
  const AppButton({
    super.key,
    this.text,
    this.label,
    this.icon,
    this.iconWidget,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
    this.loading = false,
    this.tooltip,
    this.borderRadius,
    this.padding,
    this.focusNode,
  });

  /// Primary shortcut: label/Icon sebagai Widget
  factory AppButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget label,
    Widget? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    String? tooltip,
  }) =>
      AppButton(
        key: key,
        onPressed: onPressed,
        label: label,
        iconWidget: icon,
        style: AppButtonStyle.primary,
        size: size,
        fullWidth: fullWidth,
        loading: loading,
        tooltip: tooltip,
      );

  factory AppButton.tonal({
    Key? key,
    required VoidCallback? onPressed,
    required Widget label,
    Widget? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    String? tooltip,
  }) =>
      AppButton(
        key: key,
        onPressed: onPressed,
        label: label,
        iconWidget: icon,
        style: AppButtonStyle.tonal,
        size: size,
        fullWidth: fullWidth,
        loading: loading,
        tooltip: tooltip,
      );

  factory AppButton.outline({
    Key? key,
    required VoidCallback? onPressed,
    required Widget label,
    Widget? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool fullWidth = false,
    bool loading = false,
    String? tooltip,
  }) =>
      AppButton(
        key: key,
        onPressed: onPressed,
        label: label,
        iconWidget: icon,
        style: AppButtonStyle.outline,
        size: size,
        fullWidth: fullWidth,
        loading: loading,
        tooltip: tooltip,
      );

  /// Label teks (opsional jika pakai [label] Widget)
  final String? text;

  /// Label Widget (lebih fleksibel). Jika null, akan memakai [text].
  final Widget? label;

  /// Ikon (legacy) – hanya dipakai jika [iconWidget] null
  final IconData? icon;

  /// Ikon sebagai Widget untuk kontrol penuh
  final Widget? iconWidget;

  /// Callback tekan; jika null tombol dianggap disabled
  final VoidCallback? onPressed;

  final AppButtonStyle style;
  final AppButtonSize size;
  final bool fullWidth;
  final bool loading;
  final String? tooltip;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final FocusNode? focusNode;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovering = false;
  bool _pressed = false;
  bool _focused = false;

  void _handleAction() {
    if (widget.loading || widget.onPressed == null) return;
    widget.onPressed!.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(12);
    final disabled = widget.onPressed == null || widget.loading;

    final spec = _tokens(theme, widget.style,
        disabled: disabled,
        hovering: _hovering,
        pressed: _pressed,
        focused: _focused);
    final sizes = _sizes(widget.size);

    final iconWidget = widget.iconWidget ??
        (widget.icon != null
            ? Icon(widget.icon, size: sizes.icon, color: spec.fgColor)
            : null);

    final textWidget = widget.label ??
        Text(
          widget.text ?? '',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            fontSize: sizes.font,
            color: spec.fgColor,
          ),
        );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: sizes.icon,
            height: sizes.icon,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        else if (iconWidget != null) ...[
          IconTheme.merge(
            data: IconThemeData(size: sizes.icon, color: spec.fgColor),
            child: iconWidget,
          ),
          SizedBox(width: sizes.gap),
        ],
        Flexible(
            child: DefaultTextStyle.merge(
                style: TextStyle(color: spec.fgColor), child: textWidget)),
      ],
    );

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: widget.padding ??
          EdgeInsets.symmetric(
            vertical: 1,
            horizontal: 12,
          ),
      decoration: BoxDecoration(
        color: spec.bgColor,
        gradient: spec.gradient,
        borderRadius: effectiveRadius,
        border: spec.border,
        boxShadow: spec.shadow,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minHeight: sizes.minHeight,
            minWidth: widget.fullWidth ? double.infinity : 0),
        child: Center(child: content),
      ),
    );

    final focusable = FocusableActionDetector(
      focusNode: widget.focusNode,
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovering = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      actions: <Type, Action<Intent>>{
        ActivateIntent:
            CallbackAction<ActivateIntent>(onInvoke: (i) => _handleAction()),
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: disabled ? null : _handleAction,
          child: Semantics(
            button: true,
            enabled: !disabled,
            label: widget.tooltip ?? (widget.text ?? 'Tombol'),
            child: button,
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.trim().isNotEmpty) {
      return Tooltip(message: widget.tooltip!, child: focusable);
    }
    return focusable;
  }
}

enum AppButtonStyle { primary, tonal, outline }

enum AppButtonSize { small, medium, large }

class _ButtonSizes {
  const _ButtonSizes(
      this.font, this.icon, this.vPad, this.hPad, this.minHeight, this.gap);
  final double font;
  final double icon;
  final double vPad;
  final double hPad;
  final double minHeight;
  final double gap;
}

_ButtonSizes _sizes(AppButtonSize size) {
  switch (size) {
    case AppButtonSize.small:
      return const _ButtonSizes(13, 16, 8, 14, 36, 6);
    case AppButtonSize.large:
      return const _ButtonSizes(16, 20, 14, 22, 48, 10);
    case AppButtonSize.medium:
    default:
      return const _ButtonSizes(14, 18, 12, 18, 44, 8);
  }
}

class _ButtonTokens {
  _ButtonTokens({
    this.bgColor,
    this.fgColor,
    this.gradient,
    this.border,
    this.shadow,
  });
  final Color? bgColor;
  final Color? fgColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
}

_ButtonTokens _tokens(
  ThemeData theme,
  AppButtonStyle style, {
  required bool disabled,
  required bool hovering,
  required bool pressed,
  required bool focused,
}) {
  final cs = theme.colorScheme;
  final onSurface = cs.onSurface.withOpacity(0.38);
  final elevationShadow = <BoxShadow>[
    BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 10,
        offset: const Offset(0, 3)),
  ];

  if (disabled) {
    switch (style) {
      case AppButtonStyle.primary:
        return _ButtonTokens(
          bgColor: cs.primary.withOpacity(0.28),
          fgColor: cs.onPrimary.withOpacity(0.6),
        );
      case AppButtonStyle.tonal:
        return _ButtonTokens(
          bgColor: cs.surfaceVariant.withOpacity(0.6),
          fgColor: cs.onSurface.withOpacity(0.45),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        );
      case AppButtonStyle.outline:
        return _ButtonTokens(
          bgColor: cs.surface,
          fgColor: onSurface,
          border: Border.all(color: cs.outline.withOpacity(0.3)),
        );
    }
  }

  final isPressed = pressed;
  final isHover = hovering;

  switch (style) {
    case AppButtonStyle.primary:
      final base1 = cs.primary;
      final base2 = cs.primaryContainer;
      final grad = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue.shade700,
          Colors.blue.shade500,
        ],
      );
      return _ButtonTokens(
        gradient: grad,
        fgColor: cs.onPrimary,
        shadow: elevationShadow,
      );
    case AppButtonStyle.tonal:
      final bg = Color.alphaBlend(
          Colors.white.withOpacity(isHover ? 0.12 : 0.08),
          cs.secondaryContainer);
      return _ButtonTokens(
        bgColor: bg,
        fgColor: cs.onSecondaryContainer,
        border: Border.all(color: cs.outline.withOpacity(0.18)),
        shadow: isHover ? elevationShadow : null,
      );
    case AppButtonStyle.outline:
      return _ButtonTokens(
        bgColor: isHover ? cs.surface.withOpacity(0.9) : cs.surface,
        fgColor: cs.primary,
        border: Border.all(
            color: cs.primary.withOpacity(isHover ? 0.6 : 0.38),
            width: focused ? 1.2 : 1),
        shadow: isHover ? elevationShadow : null,
      );
  }
}
