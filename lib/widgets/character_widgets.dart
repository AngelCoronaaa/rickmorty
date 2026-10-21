import 'package:flutter/material.dart';

import '../models/character.dart';

/// Etiqueta con punto de color según el estado del personaje.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.estado, {super.key, this.grande = false});

  final Estado estado;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final color = estado.color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: grande ? 14 : 10,
        vertical: grande ? 7 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: grande ? 9 : 7,
            height: grande ? 9 : 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color, blurRadius: 6)],
            ),
          ),
          SizedBox(width: grande ? 8 : 6),
          Text(
            estado.etiqueta,
            style: TextStyle(
              fontSize: grande ? 14 : 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Foto del personaje con carga progresiva y una inicial si no hay imagen.
class CharacterImage extends StatelessWidget {
  const CharacterImage(this.character, {super.key, this.fit = BoxFit.cover});

  final Character character;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (character.image.isEmpty) return _Inicial(character);
    return Image.network(
      character.image,
      fit: fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sincrono) => sincrono
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              child: child,
            ),
      errorBuilder: (_, _, _) => _Inicial(character),
    );
  }
}

class _Inicial extends StatelessWidget {
  const _Inicial(this.character);

  final Character character;

  @override
  Widget build(BuildContext context) {
    final color = character.status.color;
    final nombre = character.name.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.12)],
        ),
      ),
      child: Center(
        child: Text(
          nombre.isEmpty ? '?' : nombre[0].toUpperCase(),
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
