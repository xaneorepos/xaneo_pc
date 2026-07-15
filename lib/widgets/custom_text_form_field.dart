import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/scale_provider.dart';
import '../providers/theme_provider.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final FaIconData icon;
  final bool isPasswordField;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextFormField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.labelText,
    required this.icon,
    this.isPasswordField = false,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _obscureText = widget.isPasswordField;
  }

  @override
  void didUpdateWidget(covariant CustomTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final scaleProvider = Provider.of<ScaleProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final scale = scaleProvider.scale;

    Widget? suffix;
    if (widget.isPasswordField) {
      suffix = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          child: FaIcon(
            _obscureText ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            size: 16 * scale,
          ),
        ),
      );
    }

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: _obscureText,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      style: TextStyle(
        fontSize: 14 * scale,
        color: isDark ? Colors.white : Colors.black,
        fontFamily: 'Inter',
      ),
      spellCheckConfiguration: null,
      decoration: InputDecoration(
        labelText: widget.labelText,
        prefixIcon: Padding(
          padding: EdgeInsets.all(12.0 * scale),
          child: FaIcon(
            widget.icon,
            size: 16 * scale,
            color: _isFocused
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          ),
        ),
        suffixIcon: suffix != null
            ? Padding(
                padding: EdgeInsets.all(12.0 * scale),
                child: suffix,
              )
            : null,
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
            width: 1,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.white : Colors.black,
            width: 1.5,
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1,
          ),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.white : Colors.black,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          fontSize: 13 * scale,
          fontFamily: 'Inter',
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16 * scale),
      ),
    );
  }
}
