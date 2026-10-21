import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/character.dart';
import '../services/character_service.dart';
import '../services/local_character_store.dart';

/// Catálogo de personajes: páginas de la API + cambios del usuario,
/// con búsqueda y filtros.
class CharactersController extends ChangeNotifier {
  CharactersController(this._service, this._store);

  final CharacterService _service;
  final LocalCharacterStore _store;

  final List<Character> _remotos = [];
  int _pagina = 0;
  bool _hayMas = true;
  bool _cargando = false;
  bool _cargandoMas = false;
  String? _error;
  int _generacion = 0; // descarta respuestas de búsquedas anteriores
  Timer? _debounce;

  String _consulta = '';
  Estado? _estado;
  Genero? _genero;

  String get consulta => _consulta;
  Estado? get estado => _estado;
  Genero? get genero => _genero;
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  bool get hayMas => _hayMas;
  String? get error => _error;
  int get pagina => _pagina;
  bool get hayFiltros => _estado != null || _genero != null;

  /// Personajes a mostrar: los creados primero y luego los de la API,
  /// sin los eliminados y con las ediciones aplicadas.
  List<Character> get visibles => [
    ..._store.creados.where(_coincide),
    for (final c in _remotos)
      if (!_store.estaEliminado(c.id)) ?_filtrado(_store.aplicar(c)),
  ];

  Character? porId(int id) {
    for (final c in _store.creados) {
      if (c.id == id) return c;
    }
    for (final c in _remotos) {
      if (c.id == id && !_store.estaEliminado(id)) return _store.aplicar(c);
    }
    return null;
  }

  Character? _filtrado(Character c) => _coincide(c) ? c : null;

  bool _coincide(Character c) =>
      c.name.toLowerCase().contains(_consulta.toLowerCase()) &&
      (_estado == null || c.status == _estado) &&
      (_genero == null || c.gender == _genero);

  Future<void> cargar() async {
    final gen = ++_generacion;
    _cargando = true;
    _cargandoMas = false;
    _error = null;
    _remotos.clear();
    _pagina = 0;
    _hayMas = true;
    notifyListeners();
    await _traerPagina(gen);
  }

  Future<void> cargarMas() async {
    if (_cargando || _cargandoMas || !_hayMas) return;
    _error = null;
    _cargandoMas = true;
    notifyListeners();
    await _traerPagina(_generacion);
  }

  Future<void> _traerPagina(int gen) async {
    try {
      final pagina = await _service.buscar(
        page: _pagina + 1,
        name: _consulta.trim(),
        status: _estado,
        gender: _genero,
      );
      if (gen != _generacion) return;
      _pagina++;
      _remotos.addAll(pagina.results);
      _hayMas = pagina.hasMore;
    } on ApiException catch (e) {
      if (gen != _generacion) return;
      _error = e.message;
    }
    _cargando = false;
    _cargandoMas = false;
    notifyListeners();
  }

  /// Búsqueda por nombre; espera a que el usuario deje de escribir.
  void buscar(String texto) {
    _consulta = texto;
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), cargar);
  }

  void filtrar({Estado? estado, Genero? genero}) {
    if (estado == _estado && genero == _genero) return;
    _estado = estado;
    _genero = genero;
    cargar();
  }

  Future<Character> agregar(Character c) async {
    final nuevo = await _store.agregar(c);
    notifyListeners();
    return nuevo;
  }

  Future<void> editar(Character c) async {
    await _store.actualizar(c);
    notifyListeners();
  }

  Future<void> eliminar(Character c) async {
    await _store.eliminar(c);
    notifyListeners();
  }

  Future<void> restaurar(Character c) async {
    await _store.restaurar(c);
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
