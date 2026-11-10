import 'package:flutter/material.dart';

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null || message.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: colors.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.icon,
    required this.isBusy,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: isBusy ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Icon(icon),
        label: Text(label),
      );
}
