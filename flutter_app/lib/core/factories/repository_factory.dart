import '../../data/repositories/remote_auth_repository.dart';
import '../../data/repositories/remote_inventory_repository.dart';
import '../../data/repositories/remote_rate_repository.dart';
import '../../data/services/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/rate_repository.dart';

enum RepositoryType { remoteApi }

class AppRepositories {
  const AppRepositories({
    required this.apiClient,
    required this.inventory,
    required this.auth,
    required this.rate,
  });

  final ApiClient apiClient;
  final InventoryRepository inventory;
  final AuthRepository auth;
  final RateRepository rate;
}

class RepositoryFactory {
  const RepositoryFactory._();

  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static AppRepositories createApp({String baseUrl = defaultBaseUrl}) {
    final apiClient = ApiClient(baseUrl: baseUrl);
    return AppRepositories(
      apiClient: apiClient,
      inventory: RemoteInventoryRepository(apiClient),
      auth: RemoteAuthRepository(apiClient),
      rate: RemoteRateRepository(apiClient),
    );
  }

  static InventoryRepository create({
    RepositoryType type = RepositoryType.remoteApi,
    String baseUrl = defaultBaseUrl,
  }) {
    switch (type) {
      case RepositoryType.remoteApi:
        return createApp(baseUrl: baseUrl).inventory;
    }
  }
}
