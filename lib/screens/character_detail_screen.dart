import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/character.dart';
import '../theme/app_theme.dart';
import '../widgets/aparecer.dart';
import '../widgets/character_actions.dart';
import '../widgets/character_widgets.dart';
import '../widgets/glass.dart';
import '../widgets/theme_selector.dart';

/// Detalle de un personaje: foto, estado y todos sus datos.
class CharacterDetailScreen extends StatefulWidget {
  const CharacterDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen> {
  /// Último dato conocido, para no quedar en blanco mientras se cierra
  /// la pantalla tras eliminar.
  Character? _ultimo;

  Future<void> _eliminar(Character c) async {
    if (await eliminarPersonaje(context, c) && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final characters = AppScope.read(context).characters;

    return LiquidBackground(
      child: Scaffold(
        body: ListenableBuilder(
          listenable: characters,
          builder: (context, _) {
            final c = characters.porId(widget.id) ?? _ultimo;
            if (c == null) return const SizedBox.shrink();
            _ultimo = c;

            return SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    children: [
                      _barra(c),
                      const SizedBox(height: 16),
                      _foto(c),
                      const SizedBox(height: 22),
                      Aparecer(orden: 1, child: _titulo(c)),
                      const SizedBox(height: 20),
                      Aparecer(orden: 2, child: _datos(c)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _barra(Character c) {
    return Row(
      children: [
        GlassButton(
          circular: true,
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_rounded),
        ),
        const Spacer(),
        const ThemeButton(),
        const SizedBox(width: 10),
        GlassButton(
          circular: true,
          tooltip: 'Editar',
          onPressed: () => editarPersonaje(context, c),
          child: const Icon(Icons.edit_rounded),
        ),
        const SizedBox(width: 10),
        GlassButton(
          circular: true,
          tooltip: 'Eliminar',
          onPressed: () => _eliminar(c),
          child: Icon(
            Icons.delete_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _foto(Character c) {
    return GlassContainer(
      radius: 36,
      blur: 0,
      child: AspectRatio(
        aspectRatio: 1,
        child: Hero(tag: 'personaje-${c.id}', child: CharacterImage(c)),
      ),
    );
  }

  Widget _titulo(Character c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c.name,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusBadge(c.status, grande: true),
            if (c.esLocal)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppTheme.verdePortal,
                ),
                child: const Text(
                  'Creado por ti',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14181F),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _datos(Character c) {
    final filas = <(IconData, String, String)>[
      (Icons.biotech_rounded, 'Especie', c.species),
      if (c.type.isNotEmpty) (Icons.category_rounded, 'Tipo', c.type),
      (c.gender.icono, 'Género', c.gender.etiqueta),
      (Icons.favorite_rounded, 'Estado', c.status.etiqueta),
      (Icons.public_rounded, 'Origen', c.origin),
      if (c.location.isNotEmpty)
        (Icons.place_rounded, 'Última ubicación', c.location),
      if (!c.esLocal) ...[
        (Icons.movie_rounded, 'Episodios', '${c.episodes}'),
        (Icons.tag_rounded, 'ID', '#${c.id}'),
      ],
    ];

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.1),
              ),
            _Fila(
              icono: filas[i].$1,
              etiqueta: filas[i].$2,
              valor: filas[i].$3,
            ),
          ],
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final atenuado = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: AppTheme.verdePortal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: TextStyle(fontSize: 13, color: atenuado)),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
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
