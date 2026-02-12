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
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    final isMax = await windowManager.isMaximized();
    if (mounted && isMax != _isMaximized) {
      setState(() => _isMaximized = isMax);
    }
  }

  @override
  void onWindowMaximize() {
    if (mounted) {
      setState(() => _isMaximized = true);
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) {
      setState(() => _isMaximized = false);
    }
  }

  Future<void> _toggleMaximize() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Container(
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
                    // Маленький логотип
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [Colors.white, Colors.grey.shade400]
                              : [Colors.black, Colors.grey.shade700],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'X',
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'xaneo_pc',
                      style: TextStyle(
                        color: isDark 
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          WindowCaptionButton.minimize(
            brightness: isDark ? Brightness.dark : Brightness.light,
            onPressed: () async => await windowManager.minimize(),
          ),
          // Кастомная кнопка maximize/unmaximize
          _buildMaximizeButton(isDark),
          WindowCaptionButton.close(
            brightness: isDark ? Brightness.dark : Brightness.light,
            onPressed: () async => await windowManager.close(),
          ),
        ],
      ),
    );
  }

  Widget _buildMaximizeButton(bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _toggleMaximize,
        child: Tooltip(
          message: _isMaximized ? 'Сделать компактнее' : 'Развернуть',
          child: Container(
            width: 46,
            height: 32,
            color: Colors.transparent,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  _isMaximized 
                      ? Icons.filter_none_rounded  // Иконка "несколько окон"
                      : Icons.crop_square_rounded,  // Иконка "развернуть"
                  key: ValueKey(_isMaximized),
                  size: 16,
                  color: isDark 
                      ? Colors.white.withOpacity(0.8)
                      : Colors.black.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
