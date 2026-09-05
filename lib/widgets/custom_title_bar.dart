import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/theme_provider.dart';

class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _refreshMaximizedState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _refreshMaximizedState() async {
    final isMaximized = await windowManager.isMaximized();
    if (!mounted || _isMaximized == isMaximized) return;
    setState(() => _isMaximized = isMaximized);
  }

  Future<void> _toggleMaximized() async {
    final isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    await _refreshMaximizedState();
  }

  @override
  void onWindowMaximize() {
    if (mounted && !_isMaximized) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted && _isMaximized) setState(() => _isMaximized = false);
  }

  @override
  void onWindowRestore() {
    _refreshMaximizedState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.white.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Expanded(
              child: DragToMoveArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Официальный логотип
                      Image.asset(
                        'assets/logo.png',
                        width: 18,
                        height: 18,
                        color: isDark ? Colors.white : Colors.black,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Xaneo',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WindowCaptionButton.minimize(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    onPressed: () async => await windowManager.minimize(),
                  ),
                  if (_isMaximized)
                    WindowCaptionButton.unmaximize(
                      brightness: isDark ? Brightness.dark : Brightness.light,
                      onPressed: _toggleMaximized,
                    )
                  else
                    WindowCaptionButton.maximize(
                      brightness: isDark ? Brightness.dark : Brightness.light,
                      onPressed: _toggleMaximized,
                    ),
                  WindowCaptionButton.close(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    onPressed: () async => await windowManager.close(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
