import 'package:flutter/material.dart';

import '../../../data/models/dollar_rate.dart';
import '../../../domain/repositories/rate_repository.dart';
import '../rate/dollar_rate_card.dart';
import 'settings_section.dart';

/// Seccion de configuracion de tasa: ver, actualizar desde el BCV
/// y configurar el valor manualmente.
class RateSettingsSection extends StatefulWidget {
  const RateSettingsSection({required this.rateRepository, super.key});

  final RateRepository rateRepository;

  @override
  State<RateSettingsSection> createState() => _RateSettingsSectionState();
}

class _RateSettingsSectionState extends State<RateSettingsSection> {
  late Future<DollarRate?> _rate;
  bool _refreshing = false;
  bool _saving = false;
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _manualValue = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rate = widget.rateRepository.current();
  }

  Future<void> _refreshFromBcv() async {
    setState(() => _refreshing = true);
    try {
      final rate = await widget.rateRepository.refreshFromBcv();
      setState(() {
        _rate = Future.value(rate);
      });
      _notify('Tasa actualizada desde el BCV.');
    } catch (error) {
      _notify('No se pudo consultar el BCV: $error');
    } finally {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _saveManual() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final rate = await widget.rateRepository.setManualRate(
        double.tryParse(_manualValue.text.replaceAll(',', '.')) ?? 0,
      );
      setState(() {
        _rate = Future.value(rate);
      });
      _manualValue.clear();
      _notify('Tasa configurada manualmente.');
    } catch (error) {
      _notify('No se pudo guardar: $error');
    } finally {
      setState(() => _saving = false);
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateValue(String? value) {
    final parsed = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Introduce un valor mayor que cero.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingsSection(
      title: 'Configuracion de tasa',
      icon: Icons.currency_exchange,
      children: [
        FutureBuilder<DollarRate?>(
          future: _rate,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              );
            }
            return DollarRateCard(
              rate: snapshot.data,
              loading: _refreshing,
              onRefresh: _refreshFromBcv,
            );
          },
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _manualValue,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateValue,
                  decoration: const InputDecoration(
                    labelText: 'Tasa manual (Bs por USD)',
                    hintText: 'Ej: 897,54',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveManual,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
        Text(
          'El boton de sincronizar obtiene la tasa directamente de www.bcv.org.ve. '
          'Si el sitio no responde, configura el valor manualmente.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _manualValue.dispose();
    super.dispose();
  }
}
