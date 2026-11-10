import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/repositories/rate_repository.dart';

/// Boton con forma de billete para la barra superior.
///
/// Muestra solo el icono de billete; al pulsarlo se despliega la
/// tasa registrada para el sistema.
class SystemRateBadge extends StatefulWidget {
  const SystemRateBadge({required this.rateRepository, super.key});

  final RateRepository rateRepository;

  @override
  State<SystemRateBadge> createState() => _SystemRateBadgeState();
}

class _SystemRateBadgeState extends State<SystemRateBadge> {
  static const Color _emeraldLight = Color(0xFF10B981);
  static const Color _emeraldDark = Color(0xFF047857);

  bool _expanded = false;
  bool _loading = false;
  double? _value;
  String? _source;
  DateTime? _updatedAt;

  @override
  void initState() {
    super.initState();
    _loadRate();
  }

  /// Bolivares por USD, formateados como en la tarjeta de tasa.
  String get _formatted {
    final value = _value;
    if (value == null || value <= 0) return 'No disponible';
    return NumberFormat.currency(
      locale: 'es_ES',
      symbol: 'Bs ',
      decimalDigits: 2,
    ).format(value);
  }

  /// Etiqueta compacta junto a la tasa: origen y fecha de registro.
  String? get _detailSuffix {
    final updatedAt = _updatedAt;
    if (updatedAt == null) return null;
    final sourceLabel = _source == 'manual' ? 'manual' : 'BCV';
    final dateLabel =
        DateFormat('dd/MM').format(updatedAt.toLocal());
    return '$sourceLabel · $dateLabel';
  }

  Future<void> _loadRate() async {
    setState(() => _loading = true);
    try {
      final rate = await widget.rateRepository.current();
      if (!mounted) return;
      setState(() {
        _value = rate?.value;
        _source = rate?.source;
        _updatedAt = rate?.updatedAt;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _value = null;
        _source = null;
        _updatedAt = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildPill() {
    final iconPill = Row(
      key: const ValueKey('pill'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.payments_rounded,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 6),
        Text(
          _formatted,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final rateView = Row(
      key: const ValueKey('rate'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.payments_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          _formatted,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_detailSuffix != null) ...[
          const SizedBox(width: 6),
          Text(
            _detailSuffix!,
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_emeraldLight, _emeraldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _expanded ? _close : _open,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: 42,
            padding: EdgeInsets.symmetric(
              horizontal: _expanded ? 14 : 12,
              vertical: 6,
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _loading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : _expanded
                      ? rateView
                      : iconPill,
            ),
          ),
        ),
      ),
    );
  }

  void _open() {
    setState(() {
      _expanded = true;
    });
    _loadRate();
  }

  void _close() {
    setState(() {
      _expanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final button = RepaintBoundary(
      child: GestureDetector(
        onTap: _expanded ? _close : _open,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          child: _buildPill(),
        ),
      ),
    );
    return button;
  }
}
