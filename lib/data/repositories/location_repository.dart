import '../../core/network/api_client.dart';

class StateOption {
  final int id;
  final String name;

  const StateOption({required this.id, required this.name});

  factory StateOption.fromJson(Map<String, dynamic> json) => StateOption(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}

/// GET /locations/states — state-level only (see ApiController::stateId()'s
/// docblock for why: the full chain goes state -> mandal -> district ->
/// block -> city, but state is the only tier the app's news cards
/// actually surface, so it's the only one worth a picker for).
class LocationRepository {
  final ApiClient _client;

  LocationRepository(this._client);

  Future<List<StateOption>> getStates() async {
    final (data, _) = await _client.get('locations/states');
    return (data as List).map((e) => StateOption.fromJson(e as Map<String, dynamic>)).toList();
  }
}
