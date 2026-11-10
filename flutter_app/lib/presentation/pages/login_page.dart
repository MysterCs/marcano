import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/auth_shell.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.authController, super.key});

  final AuthController authController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _cedulaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.authController.login(
      cedula: _cedulaController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _openRegistration() {
    widget.authController.clearError();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterPage(authController: widget.authController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        title: 'Bienvenido',
        subtitle: 'Ingresa con tu cedula para gestionar tu inventario.',
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 18),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contrasena',
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
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contrasena.';
                    }
                    if (value.length < 3) {
                      return 'La contrasena debe tener al menos 3 caracteres.';
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
                        label: 'Iniciar sesion',
                        icon: Icons.login,
                        isBusy: widget.authController.isBusy,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Primera vez en Marcano?'),
                    TextButton(
                      onPressed: _openRegistration,
                      child: const Text('Crea una cuenta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
