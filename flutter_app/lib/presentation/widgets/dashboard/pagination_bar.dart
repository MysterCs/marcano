import 'package:flutter/material.dart';

/// Barra de paginacion del listado de productos.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageSelected,
    super.key,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageSelected;

  List<int> get _pages {
    final pages = <int>[];
    final from = (currentPage - 2).clamp(0, totalPages - 1);
    final to = (currentPage + 2).clamp(0, totalPages - 1);
    for (var i = from; i <= to; i++) {
      pages.add(i);
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final first = currentPage * pageSize + 1;
    final last = ((currentPage + 1) * pageSize).clamp(0, totalItems);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Mostrando $first-$last de $totalItems productos',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              onPressed:
                  currentPage > 0 ? () => onPageSelected(currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Pagina anterior',
            ),
            for (final p in _pages)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('${p + 1}'),
                  selected: p == currentPage,
                  onSelected: (_) => onPageSelected(p),
                ),
              ),
            IconButton(
              onPressed: currentPage < totalPages - 1
                  ? () => onPageSelected(currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Pagina siguiente',
            ),
          ],
        ),
      ),
    );
  }
}
