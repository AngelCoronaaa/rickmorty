import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

export '../services/auth_service.dart' show CuentaException;

/// Sesión del usuario y aspecto elegido (claro, oscuro o el del sistema).
class AppController extends ChangeNotifier {
  AppController(this._prefs, this._auth) {
    _usuario = _auth.sesion;
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _prefs.getString(_claveTema),
      orElse: () => ThemeMode.system,
    );
  }

  static const _claveTema = 'theme';

  final SharedPreferences _prefs;
  final AuthService _auth;
  String? _usuario;
  late ThemeMode _themeMode;

  String? get usuario => _usuario;
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode modo) async {
    if (modo == _themeMode) return;
    _themeMode = modo;
    notifyListeners();
    await _prefs.setString(_claveTema, modo.name);
  }

  Future<void> iniciarSesion(String usuario, String password) async {
    _usuario = await _auth.iniciarSesion(usuario, password);
    notifyListeners();
  }

  Future<void> registrar(String usuario, String password) async {
    _usuario = await _auth.registrar(usuario, password);
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    _usuario = null;
    notifyListeners();
    await _auth.cerrarSesion();
  }
}
