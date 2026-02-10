import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/theme_provider.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

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
          WindowCaptionButton.maximize(
            brightness: isDark ? Brightness.dark : Brightness.light,
            onPressed: () async => await windowManager.maximize(),
          ),
          WindowCaptionButton.close(
            brightness: isDark ? Brightness.dark : Brightness.light,
            onPressed: () async => await windowManager.close(),
          ),
        ],
      ),
    );
  }
}
