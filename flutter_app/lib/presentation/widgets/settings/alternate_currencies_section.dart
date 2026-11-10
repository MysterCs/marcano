import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/currency.dart';
import '../../../domain/repositories/rate_repository.dart';
import '../rate/bcv_currencies_picker.dart';
import 'settings_section.dart';

/// Seccion de ajustes para las monedas alternas del sistema.
///
/// Permite seleccionar divisas del BCV, editar su tasa manual y borrarlas.
class AlternateCurrenciesSection extends StatefulWidget {
  const AlternateCurrenciesSection({required this.rateRepository, super.key});

  final RateRepository rateRepository;

  @override
  State<AlternateCurrenciesSection> createState() =>
      _AlternateCurrenciesSectionState();
}

class _AlternateCurrenciesSectionState extends State<AlternateCurrenciesSection> {
  late Future<List<AlternateCurrency>> _alternates;
  bool _saving = false;
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() {
        _alternates = widget.rateRepository.alternates();
      });

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<List<AlternateCurrency>> _currentAlternates() async =>
      _alternates.catchError((_) => const <AlternateCurrency>[]);

  Future<void> _openPicker() async {
    final confirmed = await BcvCurrenciesPicker.show(
      context,
      widget.rateRepository,
    );
    if (confirmed ?? false) {
      _reload();
      _notify('Monedas alternas actualizadas.');
    }
  }

  Future<void> _addManual() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final current = await _currentAlternates();
      final items = current
          .map((currency) => <String, dynamic>{
                'name': currency.name,
                'value': currency.value,
                'source': 'manual',
              })
          .toList();
      items.add(<String, dynamic>{
        'name': _nameController.text.trim(),
        'value': double.tryParse(_rateController.text.replaceAll(',', '.')) ?? 0,
        'source': 'manual',
      });
      await widget.rateRepository.setAlternates(items);
      _nameController.clear();
      _rateController.clear();
      _reload();
      _notify('Moneda agregada.');
    } catch (error) {
      _notify('No se pudo agregar: $error');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _editRate(AlternateCurrency currency) async {
    final controller = TextEditingController(text: currency.value.toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Tasa de ${currency.name}'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Tasa (Bs por unidad)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (!(saved ?? false)) return;
    final value = double.tryParse(controller.text.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      _notify('Valor invalido.');
      return;
    }
    try {
      await widget.rateRepository.updateAlternate(currency.id, value);
      _reload();
      _notify('Tasa actualizada.');
    } catch (error) {
      _notify('No se pudo actualizar: $error');
    }
    controller.dispose();
  }

  Future<void> _remove(AlternateCurrency currency) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Quitar ${currency.name}'),
        content: Text(
            'Dejara de ser moneda alterna del sistema. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    try {
      await widget.rateRepository.deleteAlternate(currency.id);
      _reload();
      _notify('${currency.name} quitada.');
    } catch (error) {
      _notify('No se pudo quitar: $error');
    }
  }

  String _dateSuffix(AlternateCurrency currency) {
    final updatedAt = currency.updatedAt;
    if (updatedAt == null) return '';
    final formatted =
        DateFormat('dd/MM/yyyy HH:mm').format(updatedAt.toLocal());
    return ' · $formatted';
  }

  String? _validateManualName(String? value) =>
      (value == null || value.trim().isEmpty)
          ? 'Nombre obligatorio.'
          : null;

  String? _validateManualRate(String? value) {
    final parsed = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Tasa mayor que cero.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => SettingsSection(
        title: 'Monedas alternas del sistema',
        icon: Icons.public,
        children: [
          OutlinedButton.icon(
            onPressed: _openPicker,
            icon: const Icon(Icons.currency_exchange),
            label: const Text('Seleccionar divisas del BCV'),
          ),
          FutureBuilder<List<AlternateCurrency>>(
            future: _alternates,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'No se pudieron cargar las monedas: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              final currencies = snapshot.requireData;
              if (currencies.isEmpty) {
                return Text(
                  'Sin monedas alternas. Selecciona divisas del BCV o agrega una luego.',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              return Column(
                children: [
                  for (final currency in currencies)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        currency.source == 'bcv'
                            ? Icons.language
                            : Icons.edit_outlined,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      title: Text(currency.name),
                      subtitle: Text(
                        currency.source == 'bcv'
                            ? 'Tasa BCV${_dateSuffix(currency)}'
                            : 'Tasa manual${_dateSuffix(currency)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            NumberFormat.currency(
                              locale: 'es_ES',
                              symbol: 'Bs ',
                              decimalDigits: 2,
                            ).format(currency.value),
                          ),
                          IconButton(
                            onPressed: () => _editRate(currency),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Editar tasa',
                          ),
                          IconButton(
                            onPressed: () => _remove(currency),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Quitar moneda',
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const Divider(),
          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de moneda',
                      hintText: 'Ej: Euro',
                    ),
                    validator: _validateManualName,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Tasa',
                      hintText: '1001,19',
                    ),
                    validator: _validateManualRate,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _addManual,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Puedes tener varias monedas alternas; cada una guarda su propia tasa. '
            'El nombre puede ser el que quieras.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}
