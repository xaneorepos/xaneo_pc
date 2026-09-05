import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_color_presets.dart';

/// Chat appearance preferences: wallpaper, message bubble colors, chat font
/// size and notification style. Ported (local-only, no server sync) from
/// xaneomain's `#chatsModal` (xc-settings.js) so xaneo_pc offers the same
/// chat customization as the web client.
class AppearanceProvider extends ChangeNotifier {
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  static const double _defaultFontSize =
      15.0; // matches current hardcoded bubble text size
  static const int _maxWallpaperBytes = 5 * 1024 * 1024;
  static const int _maxWallpaperDimension = 1920;

  static const _kFontSizeKey = 'appearance_chat_font_size';
  static const _kWallpaperPresetKey = 'appearance_wallpaper_preset';
  static const _kWallpaperCustomPathKey = 'appearance_wallpaper_custom_path';
  static const _kWallpaperLuminanceKey = 'appearance_wallpaper_luminance';
  static const _kMyMessageColorKey = 'appearance_my_message_color';
  static const _kOtherMessageColorKey = 'appearance_other_message_color';
  static const _kNotificationStyleKey = 'appearance_notification_style';

  double _chatFontSize = _defaultFontSize;
  ChatWallpaper _wallpaper = const ChatWallpaper();
  double? _customWallpaperLuminance;
  MessageColorSetting _myMessageColor = const MessageColorSetting();
  MessageColorSetting _otherMessageColor = const MessageColorSetting();
  NotificationStyle _notificationStyle = NotificationStyle.standard;
  bool _loaded = false;

  AppearanceProvider() {
    _load();
  }

  double get chatFontSize => _chatFontSize;
  ChatWallpaper get wallpaper => _wallpaper;
  MessageColorSetting get myMessageColor => _myMessageColor;
  MessageColorSetting get otherMessageColor => _otherMessageColor;
  NotificationStyle get notificationStyle => _notificationStyle;
  bool get isLoaded => _loaded;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    _chatFontSize = prefs.getDouble(_kFontSizeKey) ?? _defaultFontSize;

    final wallpaperPresetName = prefs.getString(_kWallpaperPresetKey);
    final wallpaperPreset = WallpaperPresetId.values.firstWhere(
      (e) => e.name == wallpaperPresetName,
      orElse: () => WallpaperPresetId.defaultWp,
    );
    _wallpaper = ChatWallpaper(
      preset: wallpaperPreset,
      customImagePath: prefs.getString(_kWallpaperCustomPathKey),
    );
    _customWallpaperLuminance = prefs.getDouble(_kWallpaperLuminanceKey);
    if (wallpaperPreset == WallpaperPresetId.custom &&
        _customWallpaperLuminance == null) {
      final customPath = _wallpaper.customImagePath;
      if (customPath != null) {
        try {
          final decoded = img.decodeImage(await File(customPath).readAsBytes());
          if (decoded != null) {
            _customWallpaperLuminance = _estimateImageLuminance(decoded);
            await prefs.setDouble(
              _kWallpaperLuminanceKey,
              _customWallpaperLuminance!,
            );
          }
        } catch (_) {}
      }
    }

    _myMessageColor = _decodeColorSetting(prefs.getString(_kMyMessageColorKey));
    _otherMessageColor = _decodeColorSetting(
      prefs.getString(_kOtherMessageColorKey),
    );

    _notificationStyle = NotificationStyle.values.firstWhere(
      (e) => e.name == prefs.getString(_kNotificationStyleKey),
      orElse: () => NotificationStyle.standard,
    );

    _loaded = true;
    notifyListeners();
  }

  MessageColorSetting _decodeColorSetting(String? raw) {
    if (raw == null) return const MessageColorSetting();
    try {
      return MessageColorSetting.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const MessageColorSetting();
    }
  }

  Future<void> setChatFontSize(double size) async {
    _chatFontSize = size.clamp(minFontSize, maxFontSize);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSizeKey, _chatFontSize);
  }

  Future<void> setWallpaperPreset(WallpaperPresetId preset) async {
    _wallpaper = ChatWallpaper(
      preset: preset,
      customImagePath: _wallpaper.customImagePath,
    );
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWallpaperPresetKey, preset.name);
  }

  /// Whether controls drawn over the chat wallpaper should use their dark
  /// appearance. This deliberately follows the wallpaper, not the app theme.
  /// [themeIsDark] is only relevant for the default wallpaper, where the chat
  /// has no separate decoration and inherits the application background.
  bool isChatBackgroundDark(bool themeIsDark) {
    switch (_wallpaper.preset) {
      case WallpaperPresetId.defaultWp:
        return themeIsDark;
      case WallpaperPresetId.dark:
        return true;
      case WallpaperPresetId.custom:
        final luminance = _customWallpaperLuminance;
        return luminance == null ? themeIsDark : luminance < 0.179;
      case WallpaperPresetId.blue:
      case WallpaperPresetId.green:
      case WallpaperPresetId.purple:
      case WallpaperPresetId.gradient:
        final colors = kWallpaperGradients[_wallpaper.preset.name]!.colors;
        final luminance =
            colors
                .map((color) => color.computeLuminance())
                .reduce((a, b) => a + b) /
            colors.length;
        return luminance < 0.179;
    }
  }

  double _estimateImageLuminance(img.Image image) {
    final stepX = math.max(1, image.width ~/ 64);
    final stepY = math.max(1, image.height ~/ 64);
    var luminance = 0.0;
    var samples = 0;

    for (var y = stepY ~/ 2; y < image.height; y += stepY) {
      for (var x = stepX ~/ 2; x < image.width; x += stepX) {
        final pixel = image.getPixel(x, y);
        double linearize(num channel) {
          final value = channel.toDouble();
          return value <= 0.04045
              ? value / 12.92
              : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
        }

        luminance +=
            0.2126 * linearize(pixel.rNormalized) +
            0.7152 * linearize(pixel.gNormalized) +
            0.0722 * linearize(pixel.bNormalized);
        samples++;
      }
    }

    return samples == 0 ? 0.0 : luminance / samples;
  }

  /// Copies [pickedPath] into the app support directory (resizing/compressing
  /// it first, mirroring the web client's canvas-based downscale step) and
  /// sets it as the active custom wallpaper. Throws a [StateError] if the
  /// source file exceeds [_maxWallpaperBytes].
  Future<void> setCustomWallpaperFromPickedFile(String pickedPath) async {
    final sourceFile = File(pickedPath);
    final bytes = await sourceFile.readAsBytes();
    if (bytes.length > _maxWallpaperBytes) {
      throw StateError('wallpaper_too_large');
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('wallpaper_decode_failed');
    }
    final resized =
        (decoded.width > _maxWallpaperDimension ||
            decoded.height > _maxWallpaperDimension)
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height
                ? _maxWallpaperDimension
                : null,
            height: decoded.height > decoded.width
                ? _maxWallpaperDimension
                : null,
          )
        : decoded;
    final encoded = img.encodeJpg(resized, quality: 80);
    final wallpaperLuminance = _estimateImageLuminance(resized);

    final appSupportDir = await getApplicationSupportDirectory();
    final wallpaperDir = Directory(p.join(appSupportDir.path, 'wallpapers'));
    await wallpaperDir.create(recursive: true);
    await _deleteExistingCustomWallpaper();
    final destPath = p.join(wallpaperDir.path, 'chat_wallpaper.jpg');
    await File(destPath).writeAsBytes(encoded);

    _wallpaper = ChatWallpaper(
      preset: WallpaperPresetId.custom,
      customImagePath: destPath,
    );
    _customWallpaperLuminance = wallpaperLuminance;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWallpaperPresetKey, WallpaperPresetId.custom.name);
    await prefs.setString(_kWallpaperCustomPathKey, destPath);
    await prefs.setDouble(_kWallpaperLuminanceKey, wallpaperLuminance);
  }

  Future<void> removeCustomWallpaper() async {
    await _deleteExistingCustomWallpaper();
    _wallpaper = const ChatWallpaper(preset: WallpaperPresetId.defaultWp);
    _customWallpaperLuminance = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kWallpaperPresetKey,
      WallpaperPresetId.defaultWp.name,
    );
    await prefs.remove(_kWallpaperCustomPathKey);
    await prefs.remove(_kWallpaperLuminanceKey);
  }

  Future<void> _deleteExistingCustomWallpaper() async {
    final path = _wallpaper.customImagePath;
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> setMyMessageColor(MessageColorSetting setting) async {
    _myMessageColor = setting;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMyMessageColorKey, jsonEncode(setting.toJson()));
  }

  Future<void> setOtherMessageColor(MessageColorSetting setting) async {
    _otherMessageColor = setting;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOtherMessageColorKey, jsonEncode(setting.toJson()));
  }

  Future<void> setNotificationStyle(NotificationStyle style) async {
    _notificationStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotificationStyleKey, style.name);
  }
}
