import 'package:flutter/material.dart';

import '../../../data/models/currency.dart';
import '../../../domain/repositories/rate_repository.dart';

/// Dialogo que muestra todas las divisas del BCV y permite seleccionar
/// las monedas alternas del sistema (una o varias).
class BcvCurrenciesPicker extends StatefulWidget {
  const BcvCurrenciesPicker({required this.rateRepository, super.key});

  final RateRepository rateRepository;

  static Future<bool?> show(BuildContext context, RateRepository rateRepository) =>
      showDialog<bool>(
        context: context,
        builder: (_) => BcvCurrenciesPicker(rateRepository: rateRepository),
      );

  @override
  State<BcvCurrenciesPicker> createState() => _BcvCurrenciesPickerState();
}

class _BcvCurrenciesPickerState extends State<BcvCurrenciesPicker> {
  late Future<List<BcvCurrency>> _currencies;
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _currencies = _load();
  }

  Future<List<BcvCurrency>> _load() async {
    final currencies = await widget.rateRepository.bcvCurrencies();
    return currencies;
  }

  Future<void> _confirm() async {
    final currencies = await _currencies.catchError((_) => const <BcvCurrency>[]);
    if (!mounted) return;
    final chosen = currencies
        .where((currency) => _selected.contains(currency.name))
        .map((currency) => currency.toJson())
        .toList(growable: false);
    Navigator.of(context).pop(true);
    await widget.rateRepository.setAlternates(chosen);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Divisas del BCV'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona las monedas alternas del sistema. '
                'Cada moneda elegida obtendra su tasa del BCV.',
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<BcvCurrency>>(
                future: _currencies,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'No se pudo consultar el BCV: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  final currencies = snapshot.requireData;
                  if (currencies.isEmpty) {
                    return const Text(
                        'El BCV no publico divisas en este momento.');
                  }
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final currency in currencies)
                            CheckboxListTile(
                              dense: true,
                              value: _selected.contains(currency.name),
                              title: Text(currency.name),
                              subtitle: Text(
                                'Bs ${currency.value.toStringAsFixed(2)}',
                              ),
                              onChanged: (checked) => setState(() {
                                final isSelected = checked ?? false;
                                if (isSelected) {
                                  _selected.add(currency.name);
                                } else {
                                  _selected.remove(currency.name);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: _selected.isEmpty ? null : _confirm,
            icon: const Icon(Icons.check),
            label: Text('Usar ${_selected.length} monedas'),
          ),
        ],
      );
}
