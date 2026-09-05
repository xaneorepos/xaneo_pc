import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../providers/scale_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/settings_modal.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stepCount = 3;

  int _step = 0;
  bool _leaving = false;

  void _selectStep(int value) {
    if (value < 0 || value >= _stepCount || value == _step) return;
    setState(() => _step = value);
  }

  void _next() {
    if (_step < _stepCount - 1) {
      _selectStep(_step + 1);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_leaving) return;
    setState(() => _leaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final scale = context.watch<ScaleProvider?>()?.scale ?? 1.0;
    final background = isDark ? Colors.black : Colors.white;
    final foreground = isDark ? Colors.white : const Color(0xFF111111);
    final muted = isDark ? const Color(0xFF999999) : const Color(0xFF6B6B6B);

    final steps = [
      (
        l10n.welcomeTitle,
        l10n.welcomeDescription,
        'assets/onboarding_bear.png',
      ),
      (
        l10n.privacyTitle,
        l10n.privacyDescription,
        'assets/onboarding_bear_private.png',
      ),
      (
        l10n.dataStorageTitle,
        l10n.dataStorageDescription,
        'assets/onboarding_bear_database.png',
      ),
    ];
    final current = steps[_step];

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 68, 32, 68),
              child: Column(
                children: [
                  _Header(foreground: foreground, scale: scale),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        padding: EdgeInsets.symmetric(vertical: 16 * scale),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 32 * scale,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 560 * scale,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 280),
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween(
                                              begin: .96,
                                              end: 1.0,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                    child: _Mascot(
                                      asset: current.$3,
                                      key: ValueKey(_step),
                                      scale: scale,
                                      isDark: isDark,
                                    ),
                                  ),
                                  SizedBox(height: 26 * scale),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    child: Column(
                                      key: ValueKey(current.$1),
                                      children: [
                                        Text(
                                          current.$1,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: foreground,
                                            fontSize: 32 * scale,
                                            height: 1.12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        SizedBox(height: 14 * scale),
                                        Text(
                                          current.$2,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 15 * scale,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 26 * scale),
                                  _StepIndicator(
                                    current: _step,
                                    count: _stepCount,
                                    foreground: foreground,
                                    muted: isDark
                                        ? const Color(0xFF303030)
                                        : const Color(0xFFE4E4E4),
                                    onSelect: _selectStep,
                                    scale: scale,
                                  ),
                                  SizedBox(height: 28 * scale),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_step > 0) ...[
                                        TextButton(
                                          onPressed: _leaving
                                              ? null
                                              : () => _selectStep(_step - 1),
                                          style: TextButton.styleFrom(
                                            foregroundColor: foreground,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 22 * scale,
                                              vertical: 17 * scale,
                                            ),
                                          ),
                                          child: Text(
                                            l10n.back,
                                            style: TextStyle(
                                              fontSize: 14 * scale,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12 * scale),
                                      ],
                                      SizedBox(
                                        width: 210 * scale,
                                        height: 54 * scale,
                                        child: FilledButton(
                                          onPressed: _leaving ? null : _next,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: foreground,
                                            foregroundColor: background,
                                            disabledBackgroundColor: foreground
                                                .withValues(alpha: .55),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    14 * scale,
                                                  ),
                                            ),
                                          ),
                                          child: _leaving
                                              ? SizedBox.square(
                                                  dimension: 18 * scale,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: background,
                                                      ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _step == _stepCount - 1
                                                          ? l10n.finishButton
                                                          : l10n.continueButton,
                                                      style: TextStyle(
                                                        fontSize: 15 * scale,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(width: 9 * scale),
                                                    Icon(
                                                      _step == _stepCount - 1
                                                          ? Icons.login_rounded
                                                          : Icons
                                                                .arrow_forward_rounded,
                                                      size: 19 * scale,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned.fill(child: SettingsButton()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: TextButton(
                onPressed: _leaving ? null : _finish,
                style: TextButton.styleFrom(
                  foregroundColor: foreground.withValues(alpha: .62),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(l10n.skip, style: TextStyle(fontSize: 14 * scale)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mascot extends StatelessWidget {
  const _Mascot({
    super.key,
    required this.asset,
    required this.scale,
    required this.isDark,
  });

  final String asset;
  final double scale;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    width: 286 * scale,
    height: 286 * scale,
    padding: EdgeInsets.all(14 * scale),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(64 * scale),
      border: isDark
          ? Border.all(color: const Color(0xFF1E1E1E), width: 1)
          : null,
    ),
    child: Image.asset(asset, fit: BoxFit.contain),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.foreground, required this.scale});

  final Color foreground;
  final double scale;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44 * scale,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/logo.png',
          width: 64 * scale,
          height: 44 * scale,
          color: foreground,
          colorBlendMode: BlendMode.srcIn,
        ),
      ],
    ),
  );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.current,
    required this.count,
    required this.foreground,
    required this.muted,
    required this.onSelect,
    required this.scale,
  });

  final int current;
  final int count;
  final Color foreground;
  final Color muted;
  final ValueChanged<int> onSelect;
  final double scale;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(count, (index) {
      final active = index == current;
      return InkWell(
        onTap: () => onSelect(index),
        borderRadius: BorderRadius.circular(20 * scale),
        child: Padding(
          padding: EdgeInsets.all(5 * scale),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (active ? 26 : 8) * scale,
            height: 8 * scale,
            decoration: BoxDecoration(
              color: active ? foreground : muted,
              borderRadius: BorderRadius.circular(20 * scale),
            ),
          ),
        ),
      );
    }),
  );
}
