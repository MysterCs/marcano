import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/product.dart';

/// Tarjeta de auditoria: muestra quien hizo la ultima modificacion del producto.
class AuditInfoCard extends StatelessWidget {
  const AuditInfoCard({
    required this.product,
    required this.format,
    super.key,
  });

  final Product product;
  final DateFormat format;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updated = product.updatedByUserName != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            updated ? Icons.verified_user_outlined : Icons.info_outline,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  updated
                      ? 'Ultima modificacion por ${product.updatedByUserName}'
                      : 'Sin modificaciones registradas',
                  style: theme.textTheme.bodyMedium,
                ),
                if (product.updatedAt != null)
                  Text(
                    'Fecha: ${format.format(product.updatedAt!.toLocal())}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
