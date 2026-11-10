import '../../data/models/currency.dart';
import '../../data/models/dollar_rate.dart';

abstract interface class RateRepository {
  Future<DollarRate?> current();

  Future<DollarRate> refreshFromBcv();

  Future<DollarRate> setManualRate(double value);

  Future<List<BcvCurrency>> bcvCurrencies();

  Future<List<AlternateCurrency>> alternates();

  Future<List<AlternateCurrency>> setAlternates(
    List<Map<String, dynamic>> items,
  );

  Future<AlternateCurrency> updateAlternate(int id, double value);

  Future<void> deleteAlternate(int id);
}
