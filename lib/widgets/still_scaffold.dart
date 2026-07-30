import 'package:flutter/material.dart';

import '../core/theme/still_theme.dart';
import '../core/theme/tokens.dart';
import 'still_tab_bar.dart';

class StillScaffold extends StatelessWidget {
  const StillScaffold({
    super.key,
    required this.tab,
    required this.onSelectTab,
    required this.child,
    this.topPadding = 22,
    this.horizontalPadding = StillMetrics.gutter,
    this.scrollable = true,
    this.overlay,
  });

  final StillTab tab;
  final ValueChanged<StillTab> onSelectTab;
  final Widget child;

  final double topPadding;

  final double horizontalPadding;

  final bool scrollable;

  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final c = context.still;

    Widget body = Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: MediaQuery.paddingOf(context).top + topPadding,
      ),
      child: child,
    );

    if (scrollable) {
      body = SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: c.bg,

      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: body),
              StillTabBar(active: tab, onSelect: onSelectTab),
            ],
          ),
          if (overlay != null) Positioned.fill(child: overlay!),
        ],
      ),
    );
  }
}

class StillUp extends StatefulWidget {
  const StillUp({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<StillUp> createState() => _StillUpState();
}

class _StillUpState extends State<StillUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: StillMotion.up,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, StillMotion.upOffset * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
