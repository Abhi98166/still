import 'package:flutter/material.dart';

import '../core/theme/still_theme.dart';
import '../core/theme/tokens.dart';

enum StillTab {
  home('Today'),
  calendar('Calendar'),
  search('Search'),
  settings('Settings');

  const StillTab(this.label);

  final String label;
}

class StillTabBar extends StatelessWidget {
  const StillTabBar({super.key, required this.active, required this.onSelect});

  final StillTab active;
  final ValueChanged<StillTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.still;
    final t = context.type;

    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: StillMetrics.tabBarPadding,
      child: Row(
        children: [
          for (final tab in StillTab.values)
            Expanded(
              child: Semantics(
                selected: tab == active,
                button: true,
                label: tab.label,
                child: InkWell(
                  onTap: () => onSelect(tab),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: StillMetrics.tabMinHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: StillMotion.themeSwap,
                          curve: Curves.easeOut,
                          width: StillMetrics.tabDot,
                          height: StillMetrics.tabDot,
                          decoration: BoxDecoration(
                            color: tab == active ? c.clay : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tab.label,
                          style: t.tabLabel.copyWith(
                            color: tab == active ? c.ink : c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
