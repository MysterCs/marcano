import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/auth_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({required this.authController, super.key});

  final AuthController authController;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _cedulaController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await widget.authController.register(
      fullName: _nameController.text.trim(),
      cedula: _cedulaController.text.trim(),
      password: _passwordController.text,
    );
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        title: 'Crea tu cuenta',
        subtitle: 'Registrate para comenzar a administrar tu inventario.',
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa tu nombre completo.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cedulaController,
                  decoration: const InputDecoration(
                    labelText: 'Cedula',
                    hintText: 'Ej. V-12345678',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa tu cedula.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contrasena',
                    helperText: 'Minimo 3 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Mostrar contrasena'
                          : 'Ocultar contrasena',
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) {
                    if (value == null || value.length < 3) {
                      return 'La contrasena debe tener al menos 3 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmationController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contrasena',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contrasenas no coinciden.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                AnimatedBuilder(
                  animation: widget.authController,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthErrorMessage(
                        message: widget.authController.errorMessage,
                      ),
                      AuthPrimaryButton(
                        label: 'Crear cuenta e ingresar',
                        icon: Icons.person_add_alt_1,
                        isBusy: widget.authController.isBusy,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Ya tengo una cuenta'),
                ),
              ],
            ),
          ),
        ),
      );
}
