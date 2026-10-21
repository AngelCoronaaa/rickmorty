import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/character.dart';
import '../screens/character_form_screen.dart';
import 'aparecer.dart';
import 'glass.dart';

/// Abre el formulario para crear un personaje.
Future<void> agregarPersonaje(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final nuevo = await Navigator.of(context)
      .push<Character>(rutaSuave(const CharacterFormScreen()));
  if (nuevo != null) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('${nuevo.name} fue agregado')));
  }
}

/// Abre el formulario para editar [c].
Future<void> editarPersonaje(BuildContext context, Character c) async {
  final messenger = ScaffoldMessenger.of(context);
  final editado = await Navigator.of(context)
      .push<Character>(rutaSuave(CharacterFormScreen(personaje: c)));
  if (editado != null) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('${editado.name} fue actualizado')),
      );
  }
}

/// Pide confirmación y elimina [c]; permite deshacer desde un aviso.
/// Devuelve `true` si se eliminó.
Future<bool> eliminarPersonaje(BuildContext context, Character c) async {
  final characters = AppScope.read(context).characters;
  final messenger = ScaffoldMessenger.of(context);

  final confirmar = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (context) => _DialogoEliminar(c),
  );
  if (confirmar != true) return false;

  await characters.eliminar(c);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('${c.name} fue eliminado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => characters.restaurar(c),
        ),
      ),
    );
  return true;
}

class _DialogoEliminar extends StatelessWidget {
  const _DialogoEliminar(this.personaje);

  final Character personaje;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.delete_forever_rounded, size: 44, color: scheme.error),
              const SizedBox(height: 14),
              Text(
                '¿Eliminar a ${personaje.name}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dejará de aparecer en tu catálogo. Podrás deshacerlo justo '
                'después.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
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
                      tint: scheme.error.withValues(alpha: 0.92),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Center(child: Text('Eliminar')),
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
