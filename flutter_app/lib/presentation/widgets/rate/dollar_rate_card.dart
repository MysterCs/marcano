import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/dollar_rate.dart';

/// Widget global para ver la tasa del dolar (fuente BCV o manual).
class DollarRateCard extends StatelessWidget {
  const DollarRateCard({
    required this.rate,
    required this.loading,
    this.onRefresh,
    this.compact = false,
    super.key,
  });

  final DollarRate? rate;
  final bool loading;
  final VoidCallback? onRefresh;
  final bool compact;

  static final DateFormat _format = DateFormat('dd/MM/yyyy HH:mm');

  String get _formattedValue {
    final value = rate?.value;
    if (value == null || value <= 0) return 'No disponible';
    return NumberFormat.currency(
      locale: 'es_ES',
      symbol: 'Bs ',
      decimalDigits: 2,
    ).format(value);
  }

  String get _sourceLabel {
    switch (rate?.source) {
      case 'BCV':
        return 'Segun www.bcv.org.ve';
      case 'manual':
        return 'Configurada manualmente';
      default:
        return 'Tasa no configurada';
    }
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_money_rounded,
              color: colorScheme.tertiary,
              size: compact ? 20 : 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Tasa del dolar',
              style: compact
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formattedValue,
          style: compact
              ? theme.textTheme.headlineSmall
              : theme.textTheme.headlineMedium,
        ),
        Row(
          children: [
            if (rate?.source == 'BCV')
              Icon(
                Icons.language,
                size: 14,
                color: colorScheme.tertiary,
              ),
            if (rate?.source == 'manual')
              Icon(
                Icons.edit_outlined,
                size: 14,
                color: colorScheme.secondary,
              ),
            const SizedBox(width: 4),
            Text(_sourceLabel, style: theme.textTheme.bodySmall),
            if (rate?.updatedAt != null) ...[
              const SizedBox(width: 4),
              Text(
                ' · ${_format.format(rate!.updatedAt!.toLocal())}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildContent(context)),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.sync_outlined),
                  tooltip: 'Actualizar tasa',
                ),
            ],
          ),
        ),
      );
}
