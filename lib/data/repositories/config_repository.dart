import '../../core/network/api_client.dart';

class PushConfig {
  final bool enabled;
  final String? oneSignalAppId;

  PushConfig({required this.enabled, required this.oneSignalAppId});

  factory PushConfig.fromJson(Map<String, dynamic> json) => PushConfig(
        enabled: json['enabled'] as bool? ?? false,
        oneSignalAppId: json['onesignal_app_id'] as String?,
      );
}

/// GET /config/push — lets the app pick up OneSignal's App ID (and whether
/// push is turned on at all) from Admin -> Push Notifications, rather than
/// hardcoding it at build time.
class ConfigRepository {
  final ApiClient _client;

  ConfigRepository(this._client);

  Future<PushConfig> getPushConfig() async {
    final (data, _) = await _client.get('config/push');
    return PushConfig.fromJson(data as Map<String, dynamic>);
  }
}
