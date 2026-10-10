import '../models/xb_subscription_status.dart';
import 'api_service.dart';

class XbSubscriptionService {
  static final XbSubscriptionService instance = XbSubscriptionService._();
  XbSubscriptionService._();

  final ApiService _api = ApiService();

  Future<XbSubscriptionStatus?> getStatus() async {
    final response = await _api.getXbSubscriptionStatus();
    if (response.success && response.data != null) {
      return XbSubscriptionStatus.fromJson(response.data!);
    }
    return null;
  }

  Future<String?> checkout(String plan) async {
    final response = await _api.createXbSubscriptionCheckout(plan);
    if (response.success && response.data != null) {
      final payUrl = response.data!['pay_url']?.toString();
      if (payUrl != null && payUrl.isNotEmpty) {
        return payUrl;
      }
    }
    return null;
  }

  Future<bool> stopAutoRenewal() async {
    final response = await _api.stopXbSubscription();
    return response.success;
  }
}
