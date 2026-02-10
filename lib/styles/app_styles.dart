import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Класс для хранения всех стилей приложения
class AppStyles {
  // Приватный конструктор для предотвращения создания экземпляров
  AppStyles._();

  // === ОСНОВНЫЕ ЦВЕТА (зависят от темы) ===

  static Color backgroundColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return themeProvider.isDarkMode ? Colors.black : Colors.white;
  }

  static Color textPrimaryColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDarkMode ? Colors.white : Colors.black;
  }

  static Color textSecondaryColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
  }

  static Color textMutedColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDarkMode ? Colors.grey : Colors.grey.shade500;
  }

  static Color buttonBackgroundColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDarkMode ? Colors.white : Colors.black;
  }

  static Color buttonTextColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDarkMode ? Colors.black : Colors.white;
  }

  static Color modalBackgroundColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDarkMode ? Colors.grey.shade900 : Colors.white;
  }

  static Color modalHandleColor(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
  }

  // === ШРИФТЫ И РАЗМЕРЫ ===
  static const String fontFamily = 'Inter';
  
  // Размеры шрифтов
  static const double fontSizeLarge = 32.0;   // Заголовки
  static const double fontSizeMedium = 20.0;  // Описания
  static const double fontSizeNormal = 16.0;  // Кнопки, обычный текст
  static const double fontSizeSmall = 14.0;   // Подписи
  static const double fontSizeTitle = 24.0;   // Заголовки меню

  // === СТИЛИ ТЕКСТА ===
  
  /// Стиль для больших заголовков (приветствие, приватность)
  static TextStyle titleLarge(BuildContext context) {
    return TextStyle(
      fontSize: fontSizeLarge,
      fontVariations: [const FontVariation('wght', 600)],
      color: textPrimaryColor(context),
      height: 1.1,
      fontFamily: fontFamily,
    );
  }

  /// Стиль для описаний под заголовками
  static TextStyle bodyMedium(BuildContext context) {
    return TextStyle(
      fontSize: fontSizeMedium,
      fontWeight: FontWeight.w400,
      color: textSecondaryColor(context),
      fontFamily: fontFamily,
    );
  }

  /// Стиль для приглушенного текста (второй раздел)
  static TextStyle bodyMediumMuted(BuildContext context) {
    return TextStyle(
      fontSize: fontSizeMedium,
      fontWeight: FontWeight.w400,
      color: textMutedColor(context),
      fontFamily: fontFamily,
    );
  }

  /// Стиль для текста кнопок
  static TextStyle buttonText(BuildContext context) {
    return TextStyle(
      fontSize: fontSizeNormal,
      fontVariations: [const FontVariation('wght', 600)],
      color: buttonTextColor(context),
      fontFamily: fontFamily,
    );
  }

  /// Стиль для заголовков меню
  static TextStyle menuTitle(BuildContext context) {
    return TextStyle(
      color: textPrimaryColor(context),
      fontSize: fontSizeTitle,
      fontVariations: [const FontVariation('wght', 600)],
      fontFamily: fontFamily,
    );
  }

  /// Стиль для пунктов меню
  static TextStyle menuItem(BuildContext context) {
    return TextStyle(
      color: textPrimaryColor(context),
      fontSize: fontSizeNormal,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
    );
  }

  /// Стиль для подписей в меню
  static TextStyle menuSubtitle(BuildContext context) {
    return TextStyle(
      color: textSecondaryColor(context),
      fontFamily: fontFamily,
      fontSize: fontSizeSmall,
    );
  }

  // === СТИЛИ КНОПОК ===
  
  /// Стиль для основных кнопок (белые)
  static ButtonStyle primaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: buttonBackgroundColor(context),
      foregroundColor: buttonTextColor(context),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
    );
  }

  /// Стиль для иконочных кнопок
  static ButtonStyle iconButton(BuildContext context) {
    return IconButton.styleFrom(
      backgroundColor: backgroundColor(context).withOpacity(0.3),
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(8),
    );
  }

  // === СТИЛИ КОНТЕЙНЕРОВ ===
  
  /// Стиль для модальных окон (bottom sheets)
  static BoxDecoration modalDecoration(BuildContext context) {
    return BoxDecoration(
      color: modalBackgroundColor(context),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    );
  }

  /// Стиль для ручки модального окна (серая полоска сверху)
  static BoxDecoration modalHandle(BuildContext context) {
    return BoxDecoration(
      color: modalHandleColor(context),
      borderRadius: BorderRadius.circular(2),
    );
  }

  /// Стиль для текстового блока (заголовок + текст + кнопка)
  static const BoxDecoration textBlockDecoration = BoxDecoration(
    color: Colors.transparent,
  );

  // === ОТСТУПЫ И РАЗМЕРЫ ===
  
  /// Стандартные отступы
  static const EdgeInsets paddingLarge = EdgeInsets.symmetric(horizontal: 20, vertical: 10);
  static const EdgeInsets paddingMedium = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets paddingSmall = EdgeInsets.only(top: 10, right: 10);
  
  /// Отступы для контента с изображением
  static const EdgeInsets contentPadding = EdgeInsets.only(top: 16.0, left: 0, right: 0);
  
  /// Размеры
  static const double modalHandleWidth = 36.0;
  static const double modalHandleHeight = 4.0;
  static const double iconSize = 28.0;
  static const double iconSizeSmall = 24.0;
  
  /// Размеры изображений (относительно ширины экрана)
  static const double imageWidthFactor = 0.75;
  
  /// Отступы для текстового блока от низа экрана (учитывая safe area)
  static const double textBlockBottomPadding = 40.0;
  
  /// Высота текстового блока
  static const double textBlockHeight = 200.0;
  
  // === ДЛИТЕЛЬНОСТИ АНИМАЦИЙ ===
  
  /// Длительности для анимаций
  static const Duration animationDurationFast = Duration(milliseconds: 350);
  static const Duration animationDurationMedium = Duration(milliseconds: 400);
  static const Duration animationDurationSlow = Duration(milliseconds: 300);
  
  // === КРИВЫЕ АНИМАЦИЙ ===
  
  /// Кривые для анимаций
  static const Curve animationCurveDecelerate = Curves.decelerate;
  static const Curve animationCurveEaseOut = Curves.easeOutCubic;
  static const Curve animationCurveEaseInOut = Curves.easeInOut;
}
