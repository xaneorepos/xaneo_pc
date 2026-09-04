import 'dart:io';
import 'package:flutter/material.dart';

/// Direction for a custom two-color gradient, mirroring xaneomain's
/// gradient editor (`#gradientModal` in xc-settings.js).
enum GradientDirection { diagonal, vertical, horizontal }

Color colorFromHex(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

String colorToHex(Color c) =>
    '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}';

/// A user-defined two-color gradient (custom "my"/"other" message color, or
/// a custom wallpaper gradient), matching xaneomain's `customMyGradient`/
/// `customOtherGradient` model.
class GradientSpec {
  final Color color1;
  final Color color2;
  final GradientDirection direction;

  const GradientSpec({
    required this.color1,
    required this.color2,
    this.direction = GradientDirection.diagonal,
  });

  LinearGradient toLinearGradient() {
    switch (direction) {
      case GradientDirection.vertical:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color1, color2],
        );
      case GradientDirection.horizontal:
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color1, color2],
        );
      case GradientDirection.diagonal:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        );
    }
  }

  Map<String, dynamic> toJson() => {
    'color1': colorToHex(color1),
    'color2': colorToHex(color2),
    'direction': direction.name,
  };

  factory GradientSpec.fromJson(Map<String, dynamic> json) => GradientSpec(
    color1: colorFromHex(json['color1'] as String),
    color2: colorFromHex(json['color2'] as String),
    direction: GradientDirection.values.firstWhere(
      (d) => d.name == json['direction'],
      orElse: () => GradientDirection.diagonal,
    ),
  );
}

/// Which chat wallpaper preset is active, matching xaneomain's
/// `chatWallpaper` localStorage values.
enum WallpaperPresetId { defaultWp, blue, green, purple, dark, gradient, custom }

class ChatWallpaper {
  final WallpaperPresetId preset;
  final String? customImagePath;

  const ChatWallpaper({
    this.preset = WallpaperPresetId.defaultWp,
    this.customImagePath,
  });

  /// Returns null for the "default" preset, meaning: don't override the
  /// chat area's current background — preserves today's exact appearance.
  Decoration? resolveDecoration() {
    switch (preset) {
      case WallpaperPresetId.defaultWp:
        return null;
      case WallpaperPresetId.blue:
      case WallpaperPresetId.green:
      case WallpaperPresetId.purple:
      case WallpaperPresetId.gradient:
        return BoxDecoration(gradient: kWallpaperGradients[preset.name]);
      case WallpaperPresetId.dark:
        return const BoxDecoration(color: Color(0xFF1A1A1A));
      case WallpaperPresetId.custom:
        if (customImagePath == null) return null;
        final file = File(customImagePath!);
        if (!file.existsSync()) return null;
        return BoxDecoration(
          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
        );
    }
  }
}

const kWallpaperGradients = <String, LinearGradient>{
  'blue': LinearGradient(
    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  'green': LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  'purple': LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  'gradient': LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
};

/// Preset solid colors for outgoing ("my") message bubbles, values ported
/// from xaneomain's `chatMyMessageColor` presets.
const kMyMessageSolidPresets = <String, Color>{
  'blue': Color(0xFF007AFF),
  'purple': Color(0xFFAF52DE),
  'orange': Color(0xFFFF9500),
};
const kMyMessageDefaultCustomSolid = Color(0xFF007E33);
const kMyMessageGradientPresets = <String, LinearGradient>{
  'gradient1': LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  'gradient2': LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
};

/// Preset solid colors for incoming ("other") message bubbles, values
/// ported from xaneomain's `chatOtherMessageColor` presets.
const kOtherMessageSolidPresets = <String, Color>{
  'dark-blue': Color(0xFF1F2937),
  'dark-green': Color(0xFF1F2D1F),
  'dark-purple': Color(0xFF2D1B38),
};
const kOtherMessageDefaultCustomSolid = Color(0xFF222222);
const kOtherMessageGradientPresets = <String, LinearGradient>{
  'gradient3': LinearGradient(
    colors: [Color(0xFF434343), Color(0xFF000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  'gradient4': LinearGradient(
    colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
};

/// Result of resolving a [MessageColorSetting] against its preset tables:
/// either a solid color, a gradient, or neither (meaning "keep the app's
/// current default bubble styling").
class MessageColorResolution {
  final Color? solidColor;
  final LinearGradient? gradient;
  const MessageColorResolution({this.solidColor, this.gradient});
  bool get isDefault => solidColor == null && gradient == null;
}

/// A chosen "my message" or "other message" color: either a named preset,
/// a custom solid color, or a custom gradient — mirrors xaneomain's
/// `chatMyMessageColor`/`customMyColor`/`customMyGradient` trio (and the
/// "other" equivalents) collapsed into one value.
class MessageColorSetting {
  final String presetId; // 'default' | preset key | 'custom' | 'custom-gradient'
  final Color? customSolid;
  final GradientSpec? customGradient;

  const MessageColorSetting({
    this.presetId = 'default',
    this.customSolid,
    this.customGradient,
  });

  MessageColorResolution resolve({
    required Map<String, Color> solidPresets,
    required Map<String, LinearGradient> gradientPresets,
    required Color defaultCustomSolid,
  }) {
    if (presetId == 'default') return const MessageColorResolution();
    if (presetId == 'custom') {
      return MessageColorResolution(
        solidColor: customSolid ?? defaultCustomSolid,
      );
    }
    if (presetId == 'custom-gradient') {
      return MessageColorResolution(
        gradient: (customGradient ?? _fallbackGradient(gradientPresets))
            .toLinearGradient(),
      );
    }
    if (solidPresets.containsKey(presetId)) {
      return MessageColorResolution(solidColor: solidPresets[presetId]);
    }
    if (gradientPresets.containsKey(presetId)) {
      return MessageColorResolution(gradient: gradientPresets[presetId]);
    }
    return const MessageColorResolution();
  }

  GradientSpec _fallbackGradient(Map<String, LinearGradient> gradientPresets) {
    final g = gradientPresets.values.first;
    return GradientSpec(
      color1: g.colors.first,
      color2: g.colors.last,
    );
  }

  Map<String, dynamic> toJson() => {
    'presetId': presetId,
    if (customSolid != null) 'customSolid': colorToHex(customSolid!),
    if (customGradient != null) 'customGradient': customGradient!.toJson(),
  };

  factory MessageColorSetting.fromJson(Map<String, dynamic> json) =>
      MessageColorSetting(
        presetId: json['presetId'] as String? ?? 'default',
        customSolid: json['customSolid'] != null
            ? colorFromHex(json['customSolid'] as String)
            : null,
        customGradient: json['customGradient'] != null
            ? GradientSpec.fromJson(
                json['customGradient'] as Map<String, dynamic>,
              )
            : null,
      );
}

enum NotificationStyle { standard, raven }
