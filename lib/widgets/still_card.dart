import 'package:flutter/material.dart';

import '../core/theme/still_theme.dart';
import '../core/theme/tokens.dart';

class StillCard extends StatefulWidget {
  const StillCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.radius = StillRadius.card,
    this.shadow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool shadow;

  @override
  State<StillCard> createState() => _StillCardState();
}

class _StillCardState extends State<StillCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.still;

    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: _pressed && widget.onTap != null ? c.dot : c.line,
        ),
        boxShadow: widget.shadow ? StillMetrics.cardShadow(c.ink) : null,
      ),
      padding: widget.padding,
      child: widget.child,
    );

    if (widget.onTap == null) return decorated;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: decorated,
    );
  }
}

class StillGroup extends StatelessWidget {
  const StillGroup({
    super.key,
    required this.children,
    this.radius = StillRadius.group,
  });

  final List<Widget> children;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.still;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class StillLabel extends StatelessWidget {
  const StillLabel(
    this.text, {
    super.key,
    this.style = StillLabelStyle.section,
    this.color,
  });

  final String text;
  final StillLabelStyle style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    final base = switch (style) {
      StillLabelStyle.section => t.overline,
      StillLabelStyle.eyebrow => t.overlineTight,
      StillLabelStyle.group => t.overlineSmall,
      StillLabelStyle.micro => t.microLabel,
    };

    return Text(
      text.toUpperCase(),
      style: base.copyWith(color: color ?? c.muted),
    );
  }
}

enum StillLabelStyle { section, eyebrow, group, micro }
