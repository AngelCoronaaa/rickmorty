import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/characters_controller.dart';
import '../models/character.dart';
import '../theme/app_theme.dart';
import '../widgets/aparecer.dart';
import '../widgets/character_actions.dart';
import '../widgets/character_widgets.dart';
import '../widgets/glass.dart';
import '../widgets/theme_selector.dart';
import 'character_detail_screen.dart';

/// Catálogo de personajes: búsqueda, filtros y tarjetas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final CharactersController _characters = AppScope.read(context)
      .characters;
  final _busqueda = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // El catálogo sobrevive al cierre de sesión: solo se carga la primera vez.
    if (_characters.visibles.isEmpty && !_characters.cargando) {
      _characters.cargar();
    }
    _busqueda.text = _characters.consulta;
    _scroll.addListener(_revisarFinal);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _busqueda.dispose();
    super.dispose();
  }

  /// Pide la siguiente página cuando queda poco por recorrer. También se
  /// llama tras cada reconstrucción, por si la lista no llena la pantalla.
  void _revisarFinal() {
    if (!_scroll.hasClients || _characters.error != null) return;
    if (_scroll.position.extentAfter < 600) _characters.cargarMas();
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => const _DialogoCerrarSesion(),
    );
    if (confirmar == true && mounted) {
      await AppScope.read(context).controller.cerrarSesion();
    }
  }

  void _abrirDetalle(Character c) =>
      Navigator.of(context).push(rutaSuave(CharacterDetailScreen(id: c.id)));

  @override
  Widget build(BuildContext context) {
    final usuario = AppScope.of(context).controller.usuario ?? '';

    return LiquidBackground(
      child: Scaffold(
        floatingActionButton: GlassButton(
          tint: AppTheme.verdePortal.withValues(alpha: 0.92),
          onPressed: () => agregarPersonaje(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded),
              SizedBox(width: 8),
              Text('Agregar personaje'),
            ],
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListenableBuilder(
                listenable: _characters,
                builder: (context, _) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => mounted ? _revisarFinal() : null,
                  );
                  return RefreshIndicator(
                    onRefresh: _characters.cargar,
                    child: CustomScrollView(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _encabezado(usuario)),
                        SliverToBoxAdapter(child: _buscador()),
                        SliverToBoxAdapter(child: _filtros()),
                        ..._contenido(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _encabezado(String usuario) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $usuario',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: atenuado, fontSize: 15),
                ),
                const Text(
                  'Personajes',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          const ThemeButton(),
          const SizedBox(width: 10),
          GlassButton(
            circular: true,
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            child: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buscador() {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        radius: 22,
        child: TextField(
          controller: _busqueda,
          onChanged: _characters.buscar,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre…',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _busqueda.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    icon: Icon(
                      Icons.close_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      _busqueda.clear();
                      _characters.buscar('');
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _filtros() {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Column(
        children: [
          _FilaChips<Estado>(
            etiqueta: 'Estado',
            valores: Estado.values,
            seleccionado: _characters.estado,
            nombre: (e) => e.etiqueta,
            color: (e) => e.color,
            onCambio: (e) =>
                _characters.filtrar(estado: e, genero: _characters.genero),
          ),
          const SizedBox(height: 10),
          _FilaChips<Genero>(
            etiqueta: 'Género',
            valores: Genero.values,
            seleccionado: _characters.genero,
            nombre: (g) => g.etiqueta,
            onCambio: (g) =>
                _characters.filtrar(estado: _characters.estado, genero: g),
          ),
        ],
      ),
    );
  }

  List<Widget> _contenido() {
    final lista = _characters.visibles;

    if (_characters.cargando && lista.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (lista.isEmpty && _characters.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Mensaje(
            icono: Icons.wifi_off_rounded,
            titulo: _characters.error!,
            accion: 'Reintentar',
            onAccion: _characters.cargar,
          ),
        ),
      ];
    }

    if (lista.isEmpty && !_characters.hayMas) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Mensaje(
            icono: Icons.search_off_rounded,
            titulo: 'No encontramos personajes',
            detalle: 'Prueba con otro nombre o quita los filtros.',
            accion: _characters.hayFiltros || _busqueda.text.isNotEmpty
                ? 'Limpiar búsqueda'
                : null,
            onAccion: () {
              _busqueda.clear();
              _characters
                ..buscar('')
                ..filtrar();
            },
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisExtent: 290,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          itemCount: lista.length,
          itemBuilder: (context, i) {
            final c = lista[i];
            return _TarjetaPersonaje(
              key: ValueKey(c.id),
              personaje: c,
              onTap: () => _abrirDetalle(c),
              onEditar: () => editarPersonaje(context, c),
              onEliminar: () => eliminarPersonaje(context, c),
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: _PieLista(
          error: _characters.error,
          hayMas: _characters.hayMas,
          onReintentar: _characters.cargarMas,
        ),
      ),
    ];
  }
}

class _FilaChips<T> extends StatelessWidget {
  const _FilaChips({
    required this.etiqueta,
    required this.valores,
    required this.seleccionado,
    required this.nombre,
    required this.onCambio,
    this.color,
  });

  final String etiqueta;
  final List<T> valores;
  final T? seleccionado;
  final String Function(T) nombre;
  final Color Function(T)? color;
  final ValueChanged<T?> onCambio;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _Chip(
            texto: 'Todos',
            activo: seleccionado == null,
            onTap: () => onCambio(null),
            semantica: '$etiqueta: todos',
          ),
          for (final v in valores) ...[
            const SizedBox(width: 8),
            _Chip(
              texto: nombre(v),
              color: color?.call(v),
              activo: v == seleccionado,
              onTap: () => onCambio(v == seleccionado ? null : v),
              semantica: '$etiqueta: ${nombre(v)}',
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.texto,
    required this.activo,
    required this.onTap,
    required this.semantica,
    this.color,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;
  final String semantica;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = GlassPalette.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final acento = color ?? AppTheme.verdePortal;

    return Presionable(
      onTap: onTap,
      semanticLabel: semantica,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: activo ? acento.withValues(alpha: 0.28) : p.control,
          border: Border.all(
            color: activo ? acento : p.borde,
            width: activo ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: acento,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              texto,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
                color: onSurface.withValues(alpha: activo ? 1 : 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Accion { editar, eliminar }

class _TarjetaPersonaje extends StatelessWidget {
  const _TarjetaPersonaje({
    super.key,
    required this.personaje,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  final Character personaje;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final atenuado = scheme.onSurface.withValues(alpha: 0.6);

    return Presionable(
      onTap: onTap,
      semanticLabel: 'Ver detalles de ${personaje.name}',
      child: GlassContainer(
        radius: 26,
        blur: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'personaje-${personaje.id}',
                    child: CharacterImage(personaje),
                  ),
                  if (personaje.esLocal)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: _EtiquetaNuevo(),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<_Accion>(
                      tooltip: 'Opciones',
                      icon: const _BotonOpciones(),
                      onSelected: (a) => switch (a) {
                        _Accion.editar => onEditar(),
                        _Accion.eliminar => onEliminar(),
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _Accion.editar,
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.edit_rounded),
                            title: Text('Editar'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _Accion.eliminar,
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.delete_rounded,
                              color: scheme.error,
                            ),
                            title: Text(
                              'Eliminar',
                              style: TextStyle(color: scheme.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personaje.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${personaje.species} · ${personaje.gender.etiqueta}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: atenuado),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(personaje.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonOpciones extends StatelessWidget {
  const _BotonOpciones();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.45),
      ),
      child: const Icon(
        Icons.more_horiz_rounded,
        size: 20,
        color: Colors.white,
      ),
    );
  }
}

class _EtiquetaNuevo extends StatelessWidget {
  const _EtiquetaNuevo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.verdePortal,
      ),
      child: const Text(
        'Nuevo',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF14181F),
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
    this.onAccion,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 56, color: atenuado),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 6),
            Text(
              detalle!,
              textAlign: TextAlign.center,
              style: TextStyle(color: atenuado),
            ),
          ],
          if (accion != null) ...[
            const SizedBox(height: 18),
            GlassButton(onPressed: onAccion, child: Text(accion!)),
          ],
        ],
      ),
    );
  }
}

class _DialogoCerrarSesion extends StatelessWidget {
  const _DialogoCerrarSesion();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.logout_rounded, size: 40),
              const SizedBox(height: 14),
              const Text(
                '¿Cerrar sesión?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Center(child: Text('Cancelar')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      tint: AppTheme.verdePortal.withValues(alpha: 0.92),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Center(child: Text('Salir')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Final de la lista: indicador de carga o botón para reintentar.
class _PieLista extends StatelessWidget {
  const _PieLista({
    required this.error,
    required this.hayMas,
    required this.onReintentar,
  });

  final String? error;
  final bool hayMas;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final Widget contenido;
    if (error != null) {
      contenido = TextButton.icon(
        onPressed: onReintentar,
        icon: const Icon(Icons.refresh_rounded),
        label: Text('$error. Reintentar'),
      );
    } else if (hayMas) {
      contenido = const SizedBox.square(
        dimension: 26,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    } else {
      contenido = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 110),
      child: Center(child: contenido),
    );
  }
}
