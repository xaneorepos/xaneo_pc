import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import 'base_custom_modal.dart';

/// Локализация для модального окна обрезки аватарок в монохромном десктопном стиле
class _CropperL10n {
  static const Map<String, Map<String, String>> _values = {
    'ru': {
      'title': 'ОБРЕЗКА АВАТАРА',
      'subtitle': 'Перетаскивайте и масштабируйте фото мышью',
      'zoom': 'Масштаб',
      'rotate': 'Поворот',
      'rotateLeft': 'Влево 90°',
      'rotateRight': 'Вправо 90°',
      'flip': 'Отражение',
      'flipHoriz': 'По гор.',
      'flipVert': 'По верт.',
      'reset': 'Сброс',
      'cancel': 'Отмена',
      'save': 'Сохранить',
      'saveError': 'Ошибка сохранения',
    },
    'en': {
      'title': 'CROP AVATAR',
      'subtitle': 'Drag and zoom image to adjust position',
      'zoom': 'Zoom',
      'rotate': 'Rotate',
      'rotateLeft': 'Left 90°',
      'rotateRight': 'Right 90°',
      'flip': 'Flip',
      'flipHoriz': 'Horizontal',
      'flipVert': 'Vertical',
      'reset': 'Reset',
      'cancel': 'Cancel',
      'save': 'Save',
      'saveError': 'Save error',
    },
    'ar': {
      'title': 'قص الصورة الشخصية',
      'subtitle': 'اسحب وكبّر الصورة لضبط موضع الصورة الشخصية',
      'zoom': 'التكبير',
      'rotate': 'Тدوير',
      'rotateLeft': 'يسار 90°',
      'rotateRight': 'يمين 90°',
      'flip': 'قلب',
      'flipHoriz': 'أفقي',
      'flipVert': 'رأسي',
      'reset': 'إعادة ضبط',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'saveError': 'خطأ في الحفظ',
    },
    'es': {
      'title': 'RECORTAR AVATAR',
      'subtitle': 'Arrastra y ajusta el zoom de la imagen',
      'zoom': 'Zoom',
      'rotate': 'Rotar',
      'rotateLeft': 'Izquierda 90°',
      'rotateRight': 'Derecha 90°',
      'flip': 'Voltear',
      'flipHoriz': 'Horizontal',
      'flipVert': 'Vertical',
      'reset': 'Restablecer',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'saveError': 'Error al guardar',
    },
    'fr': {
      'title': 'ROGNAGE DE L\'AVATAR',
      'subtitle': 'Faites glisser et zoomez l\'image',
      'zoom': 'Zoom',
      'rotate': 'Pivoter',
      'rotateLeft': 'Gauche 90°',
      'rotateRight': 'Droite 90°',
      'flip': 'Retourner',
      'flipHoriz': 'Horizontal',
      'flipVert': 'Vertical',
      'reset': 'Réinitialiser',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'saveError': 'Erreur d\'enregistrement',
    },
    'ja': {
      'title': 'アバターの切り抜き',
      'subtitle': '画像をドラッグ＆ズームして位置を調整',
      'zoom': 'ズーム',
      'rotate': '回転',
      'rotateLeft': '左90°',
      'rotateRight': '右90°',
      'flip': '反転',
      'flipHoriz': '水平',
      'flipVert': '垂直',
      'reset': 'リセット',
      'cancel': 'キャンセル',
      'save': '保存',
      'saveError': '保存エラー',
    },
    'ko': {
      'title': '아바타 자르기',
      'subtitle': '이미지를 드래그하고 확대하여 위치를 맞추세요',
      'zoom': '확대/축소',
      'rotate': '회전',
      'rotateLeft': '왼쪽 90°',
      'rotateRight': '오른쪽 90°',
      'flip': '반전',
      'flipHoriz': '수평',
      'flipVert': '수직',
      'reset': '초기화',
      'cancel': '취소',
      'save': '저장',
      'saveError': '저장 오류',
    },
    'zh': {
      'title': '裁剪头像',
      'subtitle': '拖动并缩放图片以调整头像位置',
      'zoom': '缩放',
      'rotate': '旋转',
      'rotateLeft': '向左 90°',
      'rotateRight': '向右 90°',
      'flip': '翻转',
      'flipHoriz': '水平翻转',
      'flipVert': '垂直翻转',
      'reset': '重置',
      'cancel': '取消',
      'save': '保存',
      'saveError': '保存错误',
    },
  };

  static String get(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final dict = _values[lang] ?? _values['ru']!;
    return dict[key] ?? _values['en']![key] ?? key;
  }
}

/// Модальное окно обрезки аватара в монохромном ПК-стиле на основе BaseCustomModal
class AvatarCropper extends BaseCustomModal {
  final File imageFile;

  const AvatarCropper({super.key, required this.imageFile});

  static Future<File?> show(BuildContext context, File imageFile) {
    return BaseCustomModal.show<File>(
      context: context,
      modal: AvatarCropper(imageFile: imageFile),
      barrierLabel: 'AvatarCropperModal',
    );
  }

  @override
  State<AvatarCropper> createState() => _AvatarCropperState();
}

class _AvatarCropperState extends BaseCustomModalState<AvatarCropper> {
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;

  double _rotation = 0.0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;

  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isSaving = false;

  double? _imageAspectRatio;
  int _lastPointerCount = 1;

  @override
  double get modalWidth => 760.0;

  @override
  double get modalHeightFactor => 0.82;

  @override
  String getModalTitle(BuildContext context) {
    return _CropperL10n.get(context, 'title');
  }

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  void _loadImageDimensions() {
    final ImageProvider provider = FileImage(widget.imageFile);
    provider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          if (mounted) {
            setState(() {
              _imageAspectRatio = info.image.width / info.image.height;
            });
          }
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          if (mounted) {
            setState(() {
              _imageAspectRatio = 1.0;
            });
          }
        },
      ),
    );
  }

  void _resetTransform() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
      _rotation = 0.0;
      _flipHorizontal = false;
      _flipVertical = false;
    });
  }

  @override
  Widget buildContent(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
    double scale,
  ) {
    final panelBg = isDark ? const Color(0xFF141416) : const Color(0xFFF4F4F6);
    final borderColor = isDark ? const Color(0xFF242428) : const Color(0xFFE4E4E7);
    final textColor = isDark ? Colors.white : const Color(0xFF18181B);
    final subtextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF71717A);

    return SizedBox(
      height: 440 * scale,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10 * scale),
        child: Row(
          children: [
            // Левая часть: Интерактивный Canvas и слайдер масштаба
            Expanded(
              flex: 6,
              child: Container(
                color: isDark ? const Color(0xFF070708) : const Color(0xFFECECEF),
                child: Column(
                  children: [
                    // Область кадрирования
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (_imageAspectRatio == null) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            );
                          }

                          final double cropSize = math.min(constraints.maxWidth, constraints.maxHeight) * 0.82;
                          final double baseWidth;
                          final double baseHeight;

                          if (_imageAspectRatio! > 1.0) {
                            baseWidth = cropSize * _imageAspectRatio!;
                            baseHeight = cropSize;
                          } else {
                            baseWidth = cropSize;
                            baseHeight = cropSize / _imageAspectRatio!;
                          }

                          final bool isRotatedOdd = ((_rotation / (math.pi / 2)).round() % 2) != 0;
                          final double currentW = (isRotatedOdd ? baseHeight : baseWidth) * _scale;
                          final double currentH = (isRotatedOdd ? baseWidth : baseHeight) * _scale;

                          final double maxOffsetX = math.max(0.0, (currentW - cropSize) / 2);
                          final double maxOffsetY = math.max(0.0, (currentH - cropSize) / 2);

                          final clampedOffset = Offset(
                            _offset.dx.clamp(-maxOffsetX, maxOffsetX),
                            _offset.dy.clamp(-maxOffsetY, maxOffsetY),
                          );

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Тёмный фон подложки
                              Container(color: isDark ? const Color(0xFF000000) : const Color(0xFFE2E2E6)),

                              // RepaintBoundary с фиксированной круглой картинкой
                              RepaintBoundary(
                                key: _repaintBoundaryKey,
                                child: Container(
                                  width: cropSize,
                                  height: cropSize,
                                  clipBehavior: Clip.hardEdge,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      OverflowBox(
                                        minWidth: 0.0,
                                        maxWidth: double.infinity,
                                        minHeight: 0.0,
                                        maxHeight: double.infinity,
                                        child: Transform.translate(
                                          offset: clampedOffset,
                                          child: Transform.scale(
                                            scale: _scale,
                                            child: SizedBox(
                                              width: baseWidth,
                                              height: baseHeight,
                                              child: Transform(
                                                alignment: Alignment.center,
                                                transform: Matrix4.diagonal3Values(
                                                  _flipHorizontal ? -1.0 : 1.0,
                                                  _flipVertical ? -1.0 : 1.0,
                                                  1.0,
                                                )..rotateZ(_rotation),
                                                child: Image.file(widget.imageFile, fit: BoxFit.fill),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Строгая монохромная маска (Чёрный/Белый оверлей)
                              IgnorePointer(
                                child: CustomPaint(
                                  size: Size(constraints.maxWidth, constraints.maxHeight),
                                  painter: _MonochromeCircleOverlayPainter(
                                    cropSize: cropSize,
                                    isDark: isDark,
                                  ),
                                ),
                              ),

                              // Обработка жестов мыши/пальца
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onScaleStart: (details) {
                                    _previousScale = _scale;
                                    _offset = clampedOffset;
                                    _previousOffset = details.focalPoint;
                                    _lastPointerCount = details.pointerCount;
                                  },
                                  onScaleUpdate: (details) {
                                    if (details.pointerCount != _lastPointerCount) {
                                      _lastPointerCount = details.pointerCount;
                                      _previousOffset = details.focalPoint;
                                      return;
                                    }
                                    setState(() {
                                      _scale = math.max(1.0, math.min(4.0, _previousScale * details.scale));
                                      Offset newOffset = _offset + (details.focalPoint - _previousOffset);
                                      _offset = newOffset;
                                      _previousOffset = details.focalPoint;
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Слайдер масштаба
                    _buildZoomControlsBar(context, isDark, textColor, subtextColor, scale),
                  ],
                ),
              ),
            ),

            // Разделитель
            Container(width: 1, color: borderColor),

            // Правая часть: Панель инструментов в монохромных тонах
            Expanded(
              flex: 4,
              child: Container(
                color: panelBg,
                padding: EdgeInsets.all(18 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _CropperL10n.get(context, 'subtitle'),
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: subtextColor,
                      ),
                    ),

                    SizedBox(height: 18 * scale),

                    // Секция Поворот
                    Text(
                      _CropperL10n.get(context, 'rotate').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2 * scale,
                        color: subtextColor,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMonoButton(
                            context,
                            icon: FontAwesomeIcons.rotateLeft,
                            label: _CropperL10n.get(context, 'rotateLeft'),
                            onTap: () => setState(() => _rotation -= math.pi / 2),
                            isDark: isDark,
                            scale: scale,
                          ),
                        ),
                        SizedBox(width: 6 * scale),
                        Expanded(
                          child: _buildMonoButton(
                            context,
                            icon: FontAwesomeIcons.rotateRight,
                            label: _CropperL10n.get(context, 'rotateRight'),
                            onTap: () => setState(() => _rotation += math.pi / 2),
                            isDark: isDark,
                            scale: scale,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16 * scale),

                    // Секция Отражение
                    Text(
                      _CropperL10n.get(context, 'flip').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2 * scale,
                        color: subtextColor,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMonoButton(
                            context,
                            icon: FontAwesomeIcons.rightLeft,
                            label: _CropperL10n.get(context, 'flipHoriz'),
                            isActive: _flipHorizontal,
                            onTap: () => setState(() => _flipHorizontal = !_flipHorizontal),
                            isDark: isDark,
                            scale: scale,
                          ),
                        ),
                        SizedBox(width: 6 * scale),
                        Expanded(
                          child: _buildMonoButton(
                            context,
                            icon: FontAwesomeIcons.upDown,
                            label: _CropperL10n.get(context, 'flipVert'),
                            isActive: _flipVertical,
                            onTap: () => setState(() => _flipVertical = !_flipVertical),
                            isDark: isDark,
                            scale: scale,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16 * scale),

                    // Кнопка Сброс
                    _buildMonoButton(
                      context,
                      icon: FontAwesomeIcons.rotate,
                      label: _CropperL10n.get(context, 'reset'),
                      onTap: _resetTransform,
                      isDark: isDark,
                      scale: scale,
                    ),

                    const Spacer(),

                    // Кнопки действия (Отмена / Сохранить)
                    Row(
                      children: [
                        // Кнопка Отмена
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12 * scale),
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8 * scale),
                              ),
                            ),
                            child: Text(
                              _CropperL10n.get(context, 'cancel'),
                              style: TextStyle(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 10 * scale),

                        // Монохромная Кнопка Сохранить (Чистый контрастный чёрно-белый стиль)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveCroppedImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : const Color(0xFF18181B),
                              foregroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 12 * scale),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8 * scale),
                              ),
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    width: 16 * scale,
                                    height: 16 * scale,
                                    child: CircularProgressIndicator(
                                      color: isDark ? Colors.black : Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _CropperL10n.get(context, 'save'),
                                    style: TextStyle(
                                      fontSize: 12 * scale,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.black : Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Слайдер масштаба в монохромных тонах
  Widget _buildZoomControlsBar(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtextColor,
    double scale,
  ) {
    final activeColor = isDark ? Colors.white : const Color(0xFF18181B);
    final inactiveColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101012) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFE4E4E7),
          ),
        ),
      ),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.magnifyingGlassMinus, size: 12 * scale, color: subtextColor),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: activeColor,
                inactiveTrackColor: inactiveColor,
                thumbColor: activeColor,
                trackHeight: 2 * scale,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6 * scale),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 12 * scale),
              ),
              child: Slider(
                value: _scale.clamp(1.0, 4.0),
                min: 1.0,
                max: 4.0,
                onChanged: (val) {
                  setState(() {
                    _scale = val;
                  });
                },
              ),
            ),
          ),
          FaIcon(FontAwesomeIcons.magnifyingGlassPlus, size: 12 * scale, color: subtextColor),
          SizedBox(width: 10 * scale),
          Container(
            width: 40 * scale,
            alignment: Alignment.centerRight,
            child: Text(
              '${(_scale * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11 * scale,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Кнопка управления в строгом монохромном стиле
  Widget _buildMonoButton(
    BuildContext context, {
    required dynamic icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
    required bool isDark,
    required double scale,
  }) {
    final btnBg = isActive
        ? (isDark ? Colors.white : const Color(0xFF18181B))
        : (isDark ? const Color(0xFF1E1E22) : Colors.white);
    final borderClr = isActive
        ? (isDark ? Colors.white : const Color(0xFF18181B))
        : (isDark ? const Color(0xFF2C2C30) : const Color(0xFFE4E4E7));
    final iconColor = isActive
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B));
    final labelColor = isActive
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8 * scale),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9 * scale, horizontal: 10 * scale),
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(color: borderClr, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 12 * scale, color: iconColor),
              SizedBox(width: 6 * scale),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCroppedImage() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Boundary not found');

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to get byte data');

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/cropped_avatar_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pngBytes);
      
      if (mounted) {
        Navigator.of(context).pop(tempFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_CropperL10n.get(context, 'saveError')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

/// Строгий монохромный масочный пейнтер для аватарки (Без неоновых оттенков)
class _MonochromeCircleOverlayPainter extends CustomPainter {
  final double cropSize;
  final bool isDark;

  _MonochromeCircleOverlayPainter({required this.cropSize, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = cropSize / 2;

    final path = Path()
      ..addRect(rect)
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    final paintMask = Paint()
      ..color = (isDark ? Colors.black : const Color(0xFF121214)).withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paintMask);

    // Четкая контрастная линия круга
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isDark ? Colors.white.withValues(alpha: 0.85) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _MonochromeCircleOverlayPainter oldDelegate) {
    return oldDelegate.cropSize != cropSize || oldDelegate.isDark != isDark;
  }
}
