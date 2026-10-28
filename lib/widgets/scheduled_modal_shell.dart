import 'package:flutter/material.dart';
import 'scheduled_modal_style.dart';
import 'base_custom_modal.dart';

/// Scheduled-message content uses the same shell and transition as PC modals.
class ScheduledModalShell extends BaseCustomModal {
  const ScheduledModalShell({
    super.key,
    required this.child,
    this.width = 540,
    this.fillHeight = false,
  });
  final Widget child;
  final double width;
  final bool fillHeight;

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) => BaseCustomModal.show<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    modal: InheritedTheme.captureAll(context, Builder(builder: builder)),
  );

  @override
  State<ScheduledModalShell> createState() => _ScheduledModalShellState();
}

class _ScheduledModalShellState
    extends BaseCustomModalState<ScheduledModalShell> {
  @override
  double get modalWidth => widget.width;
  @override
  double get modalHeightFactor => widget.fillHeight ? .9 : .85;
  @override
  Widget buildContent(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
    double scale,
  ) => Theme(
    data: ScheduledModalStyle.of(context).theme(Theme.of(context)),
    child: widget.child,
  );
}
