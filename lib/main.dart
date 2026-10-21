import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_controller.dart';
import 'app/app_scope.dart';
import 'app/characters_controller.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/character_service.dart';
import 'services/local_character_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    RickMortyApp(
      controller: AppController(prefs, AuthService(prefs)),
      characters: CharactersController(
        CharacterService(),
        LocalCharacterStore(prefs),
      ),
    ),
  );
}

class RickMortyApp extends StatelessWidget {
  const RickMortyApp({
    super.key,
    required this.controller,
    required this.characters,
  });

  final AppController controller;
  final CharactersController characters;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      characters: characters,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          title: 'Rick and Morty',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro,
          darkTheme: AppTheme.oscuro,
          themeMode: controller.themeMode,
          // Duración de la transición claro ↔ oscuro: los colores del vidrio
          // y del fondo se interpolan en este tiempo.
          themeAnimationDuration: const Duration(milliseconds: 600),
          themeAnimationCurve: Curves.easeInOutCubic,
          home: const _Raiz(),
        ),
      ),
    );
  }
}

/// Sin sesión muestra el login; con sesión, el catálogo.
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final usuario = AppScope.of(context).controller.usuario;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 1.06, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: usuario == null
          ? const LoginScreen(key: ValueKey('login'))
          : const HomeScreen(key: ValueKey('home')),
    );
  }
}
