import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aparecer.dart';
import '../widgets/glass.dart';
import '../widgets/portal.dart';
import '../widgets/theme_selector.dart';

/// Inicio de sesión y registro de usuarios.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  bool _registro = false;
  bool _verPassword = false;
  bool _entrando = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  void _cambiarModo(bool registro) {
    if (registro == _registro) return;
    HapticFeedback.selectionClick();
    _formKey.currentState?.reset();
    _usuario.clear();
    _password.clear();
    _confirmar.clear();
    setState(() {
      _registro = registro;
      _error = null;
    });
  }

  void _usarDatosDePrueba() {
    HapticFeedback.selectionClick();
    setState(() {
      _usuario.text = AuthService.usuarioDemo;
      _password.text = AuthService.passwordDemo;
      _error = null;
    });
    _formKey.currentState?.validate();
  }

  String? _validarUsuario(String? valor) {
    final usuario = valor?.trim() ?? '';
    if (usuario.isEmpty) return 'Escribe tu usuario';
    if (_registro) {
      if (usuario.length < 3) return 'Escribe al menos 3 caracteres';
      if (!RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(usuario)) {
        return 'Solo letras, números, "_" y "."';
      }
    }
    return null;
  }

  String? _validarPassword(String? valor) {
    final password = valor ?? '';
    if (password.isEmpty) return 'Escribe tu contraseña';
    if (_registro && password.length < 6) return 'Usa al menos 6 caracteres';
    return null;
  }

  String? _validarConfirmacion(String? valor) {
    if (valor == null || valor.isEmpty) return 'Repite la contraseña';
    return valor != _password.text ? 'Las contraseñas no coinciden' : null;
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final controller = AppScope.read(context).controller;
    setState(() => _entrando = true);
    try {
      // Pausa breve para que se aprecie el portal girando.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (_registro) {
        await controller.registrar(_usuario.text, _password.text);
      } else {
        await controller.iniciarSesion(_usuario.text, _password.text);
      }
      HapticFeedback.mediumImpact();
    } on CuentaException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _entrando = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.6);

    return LiquidBackground(
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Aparecer(
                            orden: 0,
                            child: Center(
                              child: Portal(size: 130, rapido: _entrando),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Aparecer(
                            orden: 1,
                            child: Column(
                              children: [
                                const Text(
                                  'Rick and Morty',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _registro
                                      ? 'Crea tu cuenta para entrar al multiverso'
                                      : 'Inicia sesión para ver los personajes',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: atenuado,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          Aparecer(orden: 2, child: _formulario()),
                          const SizedBox(height: 16),
                          Aparecer(orden: 3, child: _datosDePrueba(atenuado)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(top: 12, right: 16, child: ThemeButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datosDePrueba(Color atenuado) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: _registro
          ? const SizedBox(width: double.infinity)
          : Column(
              children: [
                Text(
                  'Usuario de prueba: ${AuthService.usuarioDemo} / '
                  '${AuthService.passwordDemo}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: atenuado, fontSize: 13),
                ),
                TextButton(
                  onPressed: _entrando ? null : _usarDatosDePrueba,
                  child: const Text('Rellenar con los datos de prueba'),
                ),
              ],
            ),
    );
  }

  Widget _formulario() {
    final scheme = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSegmented<bool>(
            opciones: const [(false, 'Ingresar'), (true, 'Registrarse')],
            valor: _registro,
            onCambio: _cambiarModo,
          ),
          const SizedBox(height: 22),
          const _Etiqueta('Usuario'),
          TextFormField(
            controller: _usuario,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validarUsuario,
            decoration: const InputDecoration(
              hintText: 'Tu usuario',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 16),
          const _Etiqueta('Contraseña'),
          TextFormField(
            controller: _password,
            obscureText: !_verPassword,
            textInputAction: _registro
                ? TextInputAction.next
                : TextInputAction.done,
            autofillHints: [
              _registro ? AutofillHints.newPassword : AutofillHints.password,
            ],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: _registro ? null : (_) => _entrar(),
            validator: _validarPassword,
            decoration: InputDecoration(
              hintText: _registro ? 'Mínimo 6 caracteres' : 'Tu contraseña',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                tooltip: _verPassword
                    ? 'Ocultar contraseña'
                    : 'Mostrar contraseña',
                onPressed: () => setState(() => _verPassword = !_verPassword),
                icon: Icon(
                  _verPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _registro
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const _Etiqueta('Confirmar contraseña'),
                      TextFormField(
                        controller: _confirmar,
                        obscureText: !_verPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onFieldSubmitted: (_) => _entrar(),
                        validator: _validarConfirmacion,
                        decoration: const InputDecoration(
                          hintText: 'Repite la contraseña',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: scheme.error.withValues(alpha: 0.12),
                        border: Border.all(
                          color: scheme.error.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 20,
                            color: scheme.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: scheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            tint: AppTheme.verdePortal.withValues(alpha: 0.92),
            onPressed: _entrando ? null : _entrar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _registro ? Icons.person_add_rounded : Icons.login_rounded,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _entrando
                          ? 'Abriendo portal…'
                          : _registro
                          ? 'Crear cuenta'
                          : 'Ingresar',
                      key: ValueKey('$_entrando$_registro'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
