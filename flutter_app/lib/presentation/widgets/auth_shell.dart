import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;
            if (isWide) {
              return Row(
                children: [
                  const Expanded(child: _BrandPanel()),
                  Expanded(
                    child: ColoredBox(
                      color: const Color(0xFFF4F6FC),
                      child: SafeArea(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(40),
                            child: _AuthCard(
                              title: title,
                              subtitle: subtitle,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF172554), Color(0xFF4338CA)],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Center(
                    child: Column(
                      children: [
                        const _BrandPanel(compact: true),
                        const SizedBox(height: 28),
                        _AuthCard(
                          title: title,
                          subtitle: subtitle,
                          child: child,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          const _BrandMark(size: 64),
          const SizedBox(height: 14),
          Text(
            'Marcano Inventario',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tu negocio, siempre bajo control',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFC7D2FE)),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172554), Color(0xFF3730A3), Color(0xFF4F46E5)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  _BrandMark(size: 58),
                  SizedBox(width: 16),
                  Text(
                    'Marcano',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Controla tu inventario.\nImpulsa tus decisiones.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Existencias, compras, ventas y proyecciones en una sola plataforma, estes donde estes.',
                style: TextStyle(
                  color: Color(0xFFC7D2FE),
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _FeaturePill(icon: Icons.phone_android, label: 'Movil'),
                  _FeaturePill(icon: Icons.language, label: 'Web'),
                  _FeaturePill(icon: Icons.shield_outlined, label: 'Seguro'),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          color: Colors.white,
          size: size * 0.5,
        ),
      );
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          elevation: 12,
          shadowColor: const Color(0xFF172554).withValues(alpha: 0.16),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF172554),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 26),
                child,
              ],
            ),
          ),
        ),
      );
}
