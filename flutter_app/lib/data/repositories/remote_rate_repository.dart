import '../../domain/repositories/rate_repository.dart';
import '../models/currency.dart';
import '../models/dollar_rate.dart';
import '../services/api_client.dart';

class RemoteRateRepository implements RateRepository {
  const RemoteRateRepository(this._apiClient);

  final ApiClient _apiClient;

  Map<String, dynamic> _cast(dynamic response) =>
      (response ?? {}) as Map<String, dynamic>;

  @override
  Future<DollarRate?> current() async {
    final response = _cast(await _apiClient.getJson('/api/rate/current'));
    if (response.isEmpty) return null;
    return DollarRate.fromJson(response);
  }

  @override
  Future<DollarRate> refreshFromBcv() async {
    final response = _cast(
      await _apiClient.postJson('/api/rate/refresh', <String, dynamic>{}),
    );
    return DollarRate.fromJson(response);
  }

  @override
  Future<DollarRate> setManualRate(double value) async {
    final response = _cast(
      await _apiClient.putJson(
        '/api/rate',
        <String, dynamic>{'value': value},
      ),
    );
    return DollarRate.fromJson(response);
  }

  @override
  Future<List<BcvCurrency>> bcvCurrencies() async {
    final response = await _apiClient.getJson('/api/rate/bcv') as List<dynamic>;
    return response
        .map((item) => BcvCurrency.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<AlternateCurrency>> alternates() async {
    final response = await _apiClient.getJson('/api/rate/alternates') as List<dynamic>;
    return response
        .map((item) => AlternateCurrency.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<AlternateCurrency>> setAlternates(
    List<Map<String, dynamic>> items,
  ) async {
    final response =
        await _apiClient.putJson('/api/rate/alternates', items) as List<dynamic>;
    return response
        .map((item) => AlternateCurrency.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<AlternateCurrency> updateAlternate(int id, double value) async {
    final response = _cast(
      await _apiClient.patchJson(
        '/api/rate/alternates/$id',
        <String, dynamic>{'value': value},
      ),
    );
    return AlternateCurrency.fromJson(response);
  }

  @override
  Future<void> deleteAlternate(int id) async {
    await _apiClient.deleteJson('/api/rate/alternates/$id');
  }
}
