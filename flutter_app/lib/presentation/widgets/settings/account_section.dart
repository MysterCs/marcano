import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import 'settings_section.dart';

/// Seccion de cuenta: datos del usuario y cierre de sesion.
class AccountSection extends StatelessWidget {
  const AccountSection({
    required this.authController,
    super.key,
  });

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = authController.user;
    final initials = (user?.fullName ?? '')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();
    return SettingsSection(
      title: 'Cuenta',
      icon: Icons.person_outline,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Text(initials.isEmpty ? '?' : initials),
          ),
          title: Text(user?.fullName ?? 'Sin nombre'),
          subtitle: Text('Cedula: ${user?.cedula ?? '-'}'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => authController.logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesion'),
        ),
        Text(
          'La sesion se cierra automaticamente si el token deja de ser valido.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
