import 'package:flutter/material.dart';

/// Провайдер для управления масштабом интерфейса
class ScaleProvider extends ChangeNotifier {
  double _scale = 1.0;
  static const double _minScale = 0.7;
  static const double _maxScale = 2.0;
  static const double _scaleStep = 0.1;

  double get scale => _scale;
  double get scalePercent => (_scale * 100).roundToDouble();

  void zoomIn() {
    if (_scale < _maxScale) {
      _scale = (_scale + _scaleStep).clamp(_minScale, _maxScale);
      // Округляем до одного знака после запятой
      _scale = double.parse(_scale.toStringAsFixed(1));
      notifyListeners();
    }
  }

  void zoomOut() {
    if (_scale > _minScale) {
      _scale = (_scale - _scaleStep).clamp(_minScale, _maxScale);
      // Округляем до одного знака после запятой
      _scale = double.parse(_scale.toStringAsFixed(1));
      notifyListeners();
    }
  }

  void resetZoom() {
    _scale = 1.0;
    notifyListeners();
  }
}
