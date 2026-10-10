import '../config/feature_flags.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/xb_subscription_localizations.dart';
import '../models/xb_subscription_status.dart';
import '../providers/theme_provider.dart';
import '../services/xb_subscription_service.dart';
import 'base_custom_modal.dart';

class XbSubscriptionModal extends BaseCustomModal {
  const XbSubscriptionModal({
    super.key,
    super.modalTag = 'XB',
    super.title = 'XaneoBenefits',
  });

  static Future<void> show({required BuildContext context}) {
    if (!FeatureFlags.xbSubscriptionEnabled) return Future<void>.value();
    return BaseCustomModal.show(
      context: context,
      modal: const XbSubscriptionModal(),
      barrierLabel: 'XbSubscriptionModal',
    );
  }

  @override
  State<XbSubscriptionModal> createState() => _XbSubscriptionModalState();
}

class _XbSubscriptionModalState
    extends BaseCustomModalState<XbSubscriptionModal> {
  @override
  double get modalWidth => 540.0;

  @override
  double get modalHeightFactor => 0.88;

  String _selectedPlan = 'month'; // 'month' or 'year'
  bool _isLoading = true;
  bool _isProcessingAction = false;
  String? _errorMessage;
  String? _statusBannerMessage;

  XbSubscriptionStatus? _status;
  String? _checkoutUrl;
  bool _isCheckoutView = false;
  Timer? _checkoutPollTimer;

  final Map<String, int> _prices = {
    'month': 159,
    'year': 999,
  };

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _checkoutPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final status = await XbSubscriptionService.instance.getStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _isLoading = false;
        if (status != null) {
          if (status.checkoutPaid && status.isActive) {
            _checkoutPollTimer?.cancel();
          }
          if (status.plan == 'year' || status.plan == 'month') {
            _selectedPlan = status.plan!;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!silent) {
          _errorMessage = e.toString();
        }
      });
    }
  }

  Future<void> _handleBuy() async {
    final l10n = XbSubscriptionLocalizations.of(context);
    setState(() {
      _isProcessingAction = true;
      _errorMessage = null;
      _statusBannerMessage = l10n.text('messenger.premium.openingCheckout');
    });

    try {
      final payUrl =
          await XbSubscriptionService.instance.checkout(_selectedPlan);
      if (!mounted) return;

      if (payUrl != null && payUrl.isNotEmpty) {
        final uri = Uri.tryParse(payUrl);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        setState(() {
          _isProcessingAction = false;
          _checkoutUrl = payUrl;
          _isCheckoutView = true;
          _statusBannerMessage = null;
        });

        _checkoutPollTimer?.cancel();
        _checkoutPollTimer = Timer.periodic(
          const Duration(seconds: 10),
          (_) => _loadStatus(silent: true),
        );
      } else {
        setState(() {
          _isProcessingAction = false;
          _errorMessage =
              l10n.text('messenger.premium.paymentUnavailable');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingAction = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleStopAutoRenewal() async {
    final l10n = XbSubscriptionLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? const Color(0xFF18181B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.text('messenger.premium.stopConfirmTitle'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.text('messenger.premium.stopConfirmText'),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.text('messenger.premium.cancel'),
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.text('messenger.premium.confirmStop')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessingAction = true;
      _statusBannerMessage = l10n.text('messenger.premium.stoppingRenewal');
    });

    try {
      final ok = await XbSubscriptionService.instance.stopAutoRenewal();
      if (!mounted) return;
      setState(() {
        _isProcessingAction = false;
        if (ok) {
          _statusBannerMessage =
              l10n.text('messenger.premium.renewalStopped');
        }
      });
      await _loadStatus(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingAction = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget buildContent(
    BuildContext context,
    ScrollController scrollController,
    bool isDark,
    double scale,
  ) {
    final l10n = XbSubscriptionLocalizations.of(context);

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 8 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── BRAND HERO ──────────────────────────────────────────────────
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 5 * scale,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13 * scale,
                    color: isDark ? Colors.white70 : const Color(0xFF18181B),
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    l10n.text('messenger.premium.pill'),
                    style: TextStyle(
                      fontSize: 11.5 * scale,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12 * scale),

          Center(
            child: Text(
              l10n.text('messenger.premium.title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22 * scale,
                fontWeight: FontWeight.w800,
                color: context.xnxColor('text') ??
                    (isDark ? Colors.white : const Color(0xFF09090B)),
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(height: 6 * scale),

          Center(
            child: Text(
              l10n.text('messenger.premium.lead'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13 * scale,
                color: isDark ? Colors.white60 : const Color(0xFF71717A),
                height: 1.45,
              ),
            ),
          ),
          SizedBox(height: 20 * scale),

          if (_isLoading) ...[
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8 * scale),
                child: SizedBox(
                  width: 20 * scale,
                  height: 20 * scale,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            SizedBox(height: 12 * scale),
          ],

          // ─── STATUS BANNER (IF ACTIVE / ERROR) ───────────────────────────
          if (_errorMessage != null) ...[
            _buildMessageBanner(
              text: _errorMessage!,
              color: const Color(0xFFEF4444),
              icon: Icons.error_outline_rounded,
              isDark: isDark,
              scale: scale,
            ),
            SizedBox(height: 14 * scale),
          ],

          if (_statusBannerMessage != null) ...[
            _buildMessageBanner(
              text: _statusBannerMessage!,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
              icon: Icons.info_outline_rounded,
              isDark: isDark,
              scale: scale,
            ),
            SizedBox(height: 14 * scale),
          ],

          if (_status != null && _status!.isActive) ...[
            _buildActiveSubscriptionBanner(l10n, isDark, scale),
            SizedBox(height: 18 * scale),
          ],

          if (_isCheckoutView) ...[
            _buildCheckoutSection(l10n, isDark, scale),
          ] else ...[
            // ─── PLANS RADIOGROUP ──────────────────────────────────────────
            Text(
              l10n.text('messenger.premium.planChoice'),
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            SizedBox(height: 10 * scale),

            Row(
              children: [
                Expanded(
                  child: _buildPlanCard(
                    plan: 'month',
                    title: l10n.text('messenger.premium.planMonth'),
                    price: '${_prices['month']} ₽',
                    perPeriod: l10n.text('messenger.premium.perMonth'),
                    note: l10n.text('messenger.premium.planMonthNote'),
                    isSelected: _selectedPlan == 'month',
                    isDark: isDark,
                    scale: scale,
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: _buildPlanCard(
                    plan: 'year',
                    title: l10n.text('messenger.premium.planYear'),
                    price: '${_prices['year']} ₽',
                    perPeriod: l10n.text('messenger.premium.perYear'),
                    badge: l10n.text('messenger.premium.planYearBadge'),
                    note: l10n.text('messenger.premium.planYearNote'),
                    isSelected: _selectedPlan == 'year',
                    isDark: isDark,
                    scale: scale,
                  ),
                ),
              ],
            ),
            SizedBox(height: 22 * scale),

            // ─── BENEFITS ──────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(16 * scale),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.025)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14 * scale),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE4E4E7),
                ),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(
                    icon: Icons.tune_rounded,
                    title: l10n.text('messenger.premium.benefitCustomization'),
                    sub: l10n.text('messenger.premium.benefitCustomizationSub'),
                    isDark: isDark,
                    scale: scale,
                  ),
                  Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    height: 20 * scale,
                  ),
                  _buildBenefitRow(
                    icon: Icons.cloud_outlined,
                    title: l10n.text('messenger.premium.benefitUpload'),
                    sub: l10n.text('messenger.premium.benefitUploadSub'),
                    isDark: isDark,
                    scale: scale,
                  ),
                  Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    height: 20 * scale,
                  ),
                  _buildBenefitRow(
                    icon: Icons.verified_outlined,
                    title: l10n.text('messenger.premium.benefitStatus'),
                    sub: l10n.text('messenger.premium.benefitStatusSub'),
                    isDark: isDark,
                    scale: scale,
                  ),
                ],
              ),
            ),
            SizedBox(height: 22 * scale),

            // ─── ACTIONS ───────────────────────────────────────────────────
            _buildActions(l10n, isDark, scale),
          ],

          SizedBox(height: 14 * scale),
          Center(
            child: Text(
              l10n.text('messenger.premium.footnote'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11 * scale,
                color: isDark ? Colors.white38 : const Color(0xFFA1A1AA),
                height: 1.35,
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String plan,
    required String title,
    required String price,
    required String perPeriod,
    required String note,
    String? badge,
    required bool isSelected,
    required bool isDark,
    required double scale,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.all(14 * scale),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.025)
                    : const Color(0xFFFAFAFA)),
            borderRadius: BorderRadius.circular(12 * scale),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF18181B))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE4E4E7)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8 * scale,
                      offset: Offset(0, 2 * scale),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5 * scale,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isDark
                          ? (isSelected ? Colors.white : Colors.white70)
                          : (isSelected ? const Color(0xFF18181B) : const Color(0xFF52525B)),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6 * scale,
                        vertical: 2 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF064E3B).withValues(alpha: 0.45)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6 * scale),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF059669).withValues(alpha: 0.35)
                              : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9.5 * scale,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF047857),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8 * scale),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF09090B),
                    ),
                  ),
                  SizedBox(width: 4 * scale),
                  Text(
                    perPeriod,
                    style: TextStyle(
                      fontSize: 11.5 * scale,
                      color: isDark ? Colors.white60 : const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6 * scale),
              Text(
                note,
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: isDark ? Colors.white54 : const Color(0xFF71717A),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String sub,
    required bool isDark,
    required double scale,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32 * scale,
          height: 32 * scale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8 * scale),
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16 * scale,
              color: isDark ? Colors.white : const Color(0xFF18181B),
            ),
          ),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF18181B),
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: isDark ? Colors.white60 : const Color(0xFF71717A),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSubscriptionBanner(
    XbSubscriptionLocalizations l10n,
    bool isDark,
    double scale,
  ) {
    final status = _status!;
    String dateStr = '';
    if (status.activeUntil != null) {
      final d = status.activeUntil!;
      dateStr = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    }

    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 20 * scale,
            color: const Color(0xFF10B981),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.isTestActive
                      ? l10n.text('messenger.premium.sandboxActive')
                      : l10n.text('messenger.premium.renewalEnabled'),
                  style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  SizedBox(height: 2 * scale),
                  Text(
                    l10n.text('messenger.premium.activeUntil',
                        params: {'date': dateStr}),
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(
    XbSubscriptionLocalizations l10n,
    bool isDark,
    double scale,
  ) {
    final isPaid = _status?.checkoutPaid == true && _status?.isActive == true;

    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.text('messenger.premium.checkoutTitle'),
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (_status?.checkoutMode == 'sandbox')
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 7 * scale,
                    vertical: 2 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8 * scale),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    l10n.text('messenger.premium.checkoutSandboxBadge'),
                    style: TextStyle(
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Text(
            l10n.text('messenger.premium.checkoutSubtitle'),
            style: TextStyle(
              fontSize: 12 * scale,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          SizedBox(height: 16 * scale),

          // Status indicator
          Container(
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: isPaid
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(10 * scale),
              border: Border.all(
                color: isPaid
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16 * scale,
                  height: 16 * scale,
                  child: isPaid
                      ? const Icon(Icons.check, color: Color(0xFF10B981), size: 16)
                      : CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.white70 : const Color(0xFF18181B),
                          ),
                        ),
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: Text(
                    isPaid
                        ? l10n.text('messenger.premium.checkoutPaid')
                        : l10n.text('messenger.premium.checkoutPending'),
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                      color: isPaid
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18 * scale),

          if (_checkoutUrl != null && !isPaid) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF09090B),
                foregroundColor: isDark ? const Color(0xFF09090B) : Colors.white,
                padding: EdgeInsets.symmetric(vertical: 13 * scale),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
              ),
              onPressed: () {
                final uri = Uri.tryParse(_checkoutUrl!);
                if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text(
                l10n.text('messenger.premium.payNow'),
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 8 * scale),
          ],

          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12 * scale),
              foregroundColor: isDark ? Colors.white : const Color(0xFF09090B),
              side: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFE4E4E7),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10 * scale),
              ),
            ),
            onPressed: () => _loadStatus(),
            child: Text(
              l10n.text('messenger.premium.checkStatus'),
              style: TextStyle(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 6 * scale),

          TextButton(
            onPressed: () => setState(() => _isCheckoutView = false),
            child: Text(
              l10n.text('messenger.premium.planChoice'),
              style: TextStyle(
                fontSize: 12 * scale,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    XbSubscriptionLocalizations l10n,
    bool isDark,
    double scale,
  ) {
    final isAutoRenew = _status?.isAutoRenewActive == true;
    final canStop = _status?.canStop == true;

    final buyLabel = _selectedPlan == 'year'
        ? l10n.text('messenger.premium.buyYear')
        : l10n.text('messenger.premium.buy');

    final primaryBg = isDark ? Colors.white : const Color(0xFF09090B);
    final primaryFg = isDark ? const Color(0xFF09090B) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBg,
            foregroundColor: primaryFg,
            disabledBackgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.15),
            disabledForegroundColor: isDark
                ? Colors.white38
                : Colors.black38,
            padding: EdgeInsets.symmetric(vertical: 14 * scale),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12 * scale),
            ),
          ),
          onPressed: _isProcessingAction || isAutoRenew ? null : _handleBuy,
          child: _isProcessingAction
              ? SizedBox(
                  width: 18 * scale,
                  height: 18 * scale,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryFg),
                  ),
                )
              : Text(
                  buyLabel,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
        if (canStop) ...[
          SizedBox(height: 8 * scale),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              padding: EdgeInsets.symmetric(vertical: 8 * scale),
            ),
            onPressed: _isProcessingAction ? null : _handleStopAutoRenewal,
            child: Text(
              l10n.text('messenger.premium.stopAutoRenew'),
              style: TextStyle(
                fontSize: 12.5 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        SizedBox(height: 4 * scale),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white54 : const Color(0xFF71717A),
            padding: EdgeInsets.symmetric(vertical: 8 * scale),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.text('messenger.premium.later'),
            style: TextStyle(
              fontSize: 13 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBanner({
    required String text,
    required Color color,
    required IconData icon,
    required bool isDark,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 10 * scale,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18 * scale, color: color),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12 * scale,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
