import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auth_user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/config_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/news_repository.dart';
import '../data/repositories/reporter_repository.dart';
import 'auth/auth_controller.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';

/// Root dependency-injection providers — everything else in the app reads
/// its dependencies through these rather than constructing them directly.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepository(ref.watch(apiClientProvider)),
);

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

final configRepositoryProvider = Provider<ConfigRepository>(
  (ref) => ConfigRepository(ref.watch(apiClientProvider)),
);

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepository(ref.watch(apiClientProvider)),
);

final reporterRepositoryProvider = Provider<ReporterRepository>(
  (ref) => ReporterRepository(ref.watch(apiClientProvider)),
);

/// The reader's chosen state filter for the Home feed — null means
/// unfiltered ("All India"). In-memory only for now (resets on app
/// restart); not worth persisting until this feature proves itself.
final selectedStateProvider = StateProvider<StateOption?>((ref) => null);
