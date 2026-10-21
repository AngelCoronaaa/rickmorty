import 'package:flutter/widgets.dart';

import 'app_controller.dart';
import 'characters_controller.dart';

/// Da acceso a la sesión y al catálogo desde cualquier pantalla.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required this.characters,
    required super.child,
  }) : super(notifier: controller);

  final CharactersController characters;

  AppController get controller => notifier!;

  /// Se reconstruye cuando cambia la sesión o el tema.
  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  /// Lectura sin suscribirse a cambios (útil en initState y callbacks).
  static AppScope read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!;
}
