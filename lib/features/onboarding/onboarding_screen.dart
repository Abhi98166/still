import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/theme/still_theme.dart';
import '../../widgets/still_scaffold.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _promises = [
    'Works completely offline',
    'One entry per day, autosaved',
    'Nothing is ever sent anywhere',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.still;
    final t = context.type;

    return Scaffold(
      backgroundColor: c.bg,
      body: StillUp(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 34,
              right: 34,
              top: 76,
              bottom: 46,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.clay),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.clay,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  'One quiet page\na day.',
                  style: t.display.copyWith(color: c.ink),
                ),
                const SizedBox(height: 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    "Write what you're grateful for. It stays on this device — "
                    'no account, no cloud, no noise.',
                    style: t.button.copyWith(color: c.soft, height: 1.6),
                  ),
                ),
                const SizedBox(height: 38),

                for (final promise in _promises)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: c.dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            promise,
                            style: t.bodySmall.copyWith(color: c.soft),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await ref
                          .read(settingsProvider.notifier)
                          .completeOnboarding();
                      if (context.mounted) context.go(Routes.home);
                    },
                    child: const Text('Begin'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'No sign-up. Ever.',
                    style: t.caption.copyWith(color: c.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
