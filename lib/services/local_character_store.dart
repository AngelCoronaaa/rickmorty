import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/character.dart';

/// Cambios del usuario sobre el catálogo, guardados en el dispositivo:
/// personajes nuevos, ediciones de personajes de la API y bajas.
class LocalCharacterStore {
  LocalCharacterStore(this._prefs) {
    _creados = _leerLista(_claveCreados);
    for (final c in _leerLista(_claveEditados)) {
      _editados[c.id] = c;
    }
    _eliminados.addAll(
      (_prefs.getStringList(_claveEliminados) ?? []).map(int.parse),
    );
  }

  static const _claveCreados = 'personajes_creados';
  static const _claveEditados = 'personajes_editados';
  static const _claveEliminados = 'personajes_eliminados';

  final SharedPreferences _prefs;
  late List<Character> _creados;
  final Map<int, Character> _editados = {};
  final Set<int> _eliminados = {};

  List<Character> get creados => List.unmodifiable(_creados);
  bool estaEliminado(int id) => _eliminados.contains(id);

  /// Devuelve el personaje con las ediciones del usuario aplicadas.
  Character aplicar(Character c) => _editados[c.id] ?? c;

  /// Da de alta un personaje nuevo y lo devuelve con su id.
  Future<Character> agregar(Character c) async {
    final menor = _creados.fold<int>(0, (m, e) => e.id < m ? e.id : m);
    final nuevo = c.copyWith(id: menor - 1);
    _creados = [nuevo, ..._creados];
    await _guardar();
    return nuevo;
  }

  Future<void> actualizar(Character c) async {
    if (c.esLocal) {
      _creados = [for (final e in _creados) e.id == c.id ? c : e];
    } else {
      _editados[c.id] = c;
    }
    await _guardar();
  }

  Future<void> eliminar(Character c) async {
    if (c.esLocal) {
      _creados = _creados.where((e) => e.id != c.id).toList();
    } else {
      _eliminados.add(c.id);
    }
    await _guardar();
  }

  /// Deshace [eliminar].
  Future<void> restaurar(Character c) async {
    if (c.esLocal) {
      _creados = [..._creados, c]..sort((a, b) => b.id.compareTo(a.id));
    } else {
      _eliminados.remove(c.id);
    }
    await _guardar();
  }

  List<Character> _leerLista(String clave) {
    final texto = _prefs.getString(clave);
    if (texto == null) return [];
    try {
      return [
        for (final j in jsonDecode(texto) as List)
          Character.fromJson(j as Map<String, dynamic>),
      ];
    } on Object {
      return [];
    }
  }

  Future<void> _guardar() => Future.wait([
    _prefs.setString(
      _claveCreados,
      jsonEncode(_creados.map((c) => c.toJson()).toList()),
    ),
    _prefs.setString(
      _claveEditados,
      jsonEncode(_editados.values.map((c) => c.toJson()).toList()),
    ),
    _prefs.setStringList(
      _claveEliminados,
      _eliminados.map((e) => '$e').toList(),
    ),
  ]);
}
