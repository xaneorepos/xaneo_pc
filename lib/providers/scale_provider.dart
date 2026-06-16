import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер для управления масштабом интерфейса
class ScaleProvider extends ChangeNotifier {
  double _scale = 1.0;
  static const double _minScale = 0.7;
  static const double _maxScale = 2.0;
  static const double _scaleStep = 0.1;
  static const String _prefsKey = 'app_scale_preference';

  ScaleProvider() {
    _loadScale();
  }

  double get scale => _scale;
  double get scalePercent => (_scale * 100).roundToDouble();

  Future<void> _loadScale() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble(_prefsKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> _saveScale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, _scale);
  }

  void zoomIn() {
    if (_scale < _maxScale) {
      _scale = (_scale + _scaleStep).clamp(_minScale, _maxScale);
      _scale = double.parse(_scale.toStringAsFixed(1));
      _saveScale();
      notifyListeners();
    }
  }

  void zoomOut() {
    if (_scale > _minScale) {
      _scale = (_scale - _scaleStep).clamp(_minScale, _maxScale);
      _scale = double.parse(_scale.toStringAsFixed(1));
      _saveScale();
      notifyListeners();
    }
  }

  void resetZoom() {
    _scale = 1.0;
    _saveScale();
    notifyListeners();
  }
}
