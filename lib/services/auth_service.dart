import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Error de registro o inicio de sesión, con un mensaje para mostrar.
class CuentaException implements Exception {
  const CuentaException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Acceso de usuarios sin servidor.
///
/// Las credenciales del usuario de prueba viven en las variables
/// [usuarioDemo] y [passwordDemo]; al pulsar "Ingresar" se comparan con lo
/// escrito. Las cuentas que se registran se guardan en el dispositivo con la
/// contraseña cifrada (SHA-256 con sal), nunca en texto plano.
class AuthService {
  AuthService(this._prefs);

  static const usuarioDemo = 'rick';
  static const passwordDemo = 'wubba123';

  static const _claveCuentas = 'cuentas';
  static const _claveSesion = 'sesion';

  final SharedPreferences _prefs;

  /// Usuario con la sesión abierta, si la hay.
  String? get sesion => _prefs.getString(_claveSesion);

  Future<String> iniciarSesion(String usuario, String password) async {
    final nombre = usuario.trim();

    if (nombre.toLowerCase() == usuarioDemo && password == passwordDemo) {
      return _abrir(usuarioDemo);
    }

    final cuenta = _cuentas()[nombre.toLowerCase()];
    if (cuenta != null && _hash(cuenta['sal']!, password) == cuenta['hash']) {
      return _abrir(cuenta['nombre']!);
    }
    throw const CuentaException('Usuario o contraseña incorrectos');
  }

  Future<String> registrar(String usuario, String password) async {
    final nombre = usuario.trim();
    final clave = nombre.toLowerCase();
    final cuentas = _cuentas();

    if (clave == usuarioDemo || cuentas.containsKey(clave)) {
      throw const CuentaException('Ese usuario ya existe');
    }
    final sal = base64Url.encode(
      List.generate(12, (_) => Random.secure().nextInt(256)),
    );
    cuentas[clave] = {
      'nombre': nombre,
      'sal': sal,
      'hash': _hash(sal, password),
    };
    await _prefs.setString(_claveCuentas, jsonEncode(cuentas));
    return _abrir(nombre);
  }

  Future<void> cerrarSesion() => _prefs.remove(_claveSesion);

  Future<String> _abrir(String nombre) async {
    await _prefs.setString(_claveSesion, nombre);
    return nombre;
  }

  String _hash(String sal, String password) =>
      sha256.convert(utf8.encode('$sal:$password')).toString();

  Map<String, Map<String, String>> _cuentas() {
    final texto = _prefs.getString(_claveCuentas);
    if (texto == null) return {};
    try {
      return {
        for (final e in (jsonDecode(texto) as Map).entries)
          e.key as String: Map<String, String>.from(e.value as Map),
      };
    } on Object {
      return {};
    }
  }
}
