import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickmorty/app/app_controller.dart';
import 'package:rickmorty/app/characters_controller.dart';
import 'package:rickmorty/main.dart';
import 'package:rickmorty/models/character.dart';
import 'package:rickmorty/services/auth_service.dart';
import 'package:rickmorty/services/character_service.dart';
import 'package:rickmorty/services/local_character_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ServicioFalso extends CharacterService {
  final datos = const [
    Character(
      id: 1,
      name: 'Rick Sanchez',
      status: Estado.alive,
      species: 'Human',
      gender: Genero.male,
      origin: 'Earth (C-137)',
    ),
    Character(
      id: 2,
      name: 'Morty Smith',
      status: Estado.alive,
      species: 'Human',
      gender: Genero.male,
      origin: 'unknown',
    ),
    Character(
      id: 3,
      name: 'Summer Smith',
      status: Estado.dead,
      species: 'Human',
      gender: Genero.female,
      origin: 'Earth (Replacement Dimension)',
    ),
  ];

  @override
  Future<CharacterPage> buscar({
    int page = 1,
    String name = '',
    Estado? status,
    Genero? gender,
  }) async => CharacterPage(
    datos
        .where(
          (c) =>
              c.name.toLowerCase().contains(name.toLowerCase()) &&
              (status == null || c.status == status) &&
              (gender == null || c.gender == gender),
        )
        .toList(),
    hasMore: false,
  );
}

Future<(AppController, CharactersController)> _preparar() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return (
    AppController(prefs, AuthService(prefs)),
    CharactersController(_ServicioFalso(), LocalCharacterStore(prefs)),
  );
}

/// El portal del login anima sin fin, por eso no se usa pumpAndSettle.
Future<void> _avanzar(WidgetTester tester, [int ms = 1500]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('el login exige usuario y contraseña', (tester) async {
    final (app, personajes) = await _preparar();
    _pantallaGrande(tester);
    await tester.pumpWidget(
      RickMortyApp(controller: app, characters: personajes),
    );
    await _avanzar(tester);

    await tester.tap(find.text('Ingresar').last);
    await tester.pump();

    expect(find.text('Escribe tu usuario'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);
    expect(app.usuario, isNull);
  });

  testWidgets('rechaza credenciales incorrectas y acepta las correctas', (
    tester,
  ) async {
    final (app, personajes) = await _preparar();
    _pantallaGrande(tester);
    await tester.pumpWidget(
      RickMortyApp(controller: app, characters: personajes),
    );
    await _avanzar(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'rick');
    await tester.enterText(find.byType(TextFormField).at(1), 'mal');
    await tester.tap(find.text('Ingresar').last);
    await _avanzar(tester);
    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'wubba123');
    await tester.tap(find.text('Ingresar').last);
    await _avanzar(tester);

    await _avanzar(tester, 500); // llega la primera página
    expect(app.usuario, 'rick');
    expect(find.text('Personajes'), findsOneWidget);
    expect(find.text('Morty Smith'), findsOneWidget);
  });

  testWidgets('cambia entre claro y oscuro con transición', (tester) async {
    final (app, personajes) = await _preparar();
    _pantallaGrande(tester);
    await tester.pumpWidget(
      RickMortyApp(controller: app, characters: personajes),
    );
    await _avanzar(tester);

    await app.setThemeMode(ThemeMode.light);
    await _avanzar(tester);
    final claro = Theme.of(tester.element(find.byType(Scaffold))).brightness;

    await app.setThemeMode(ThemeMode.dark);
    await tester.pump(const Duration(milliseconds: 300));
    await _avanzar(tester);
    final oscuro = Theme.of(tester.element(find.byType(Scaffold))).brightness;

    expect(claro, Brightness.light);
    expect(oscuro, Brightness.dark);
  });

  testWidgets('agregar y eliminar desde la interfaz', (tester) async {
    final (app, personajes) = await _preparar();
    await app.iniciarSesion(AuthService.usuarioDemo, AuthService.passwordDemo);
    _pantallaGrande(tester);
    await tester.pumpWidget(
      RickMortyApp(controller: app, characters: personajes),
    );
    await _avanzar(tester);

    // Formulario vacío: no guarda y muestra errores.
    await tester.tap(find.text('Agregar personaje'));
    await _avanzar(tester);
    await tester.ensureVisible(find.text('Agregar personaje').last);
    await tester.tap(find.text('Agregar personaje').last);
    await _avanzar(tester, 300);
    expect(find.text('Escribe el nombre'), findsOneWidget);
    expect(find.text('Escribe la especie'), findsOneWidget);
    expect(find.text('Escribe el origen'), findsOneWidget);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Pickle Rick');
    await tester.enterText(campos.at(1), 'Human');
    await tester.enterText(campos.at(2), 'Earth');
    await tester.enterText(campos.at(5), 'no-es-un-enlace');
    await tester.ensureVisible(find.text('Agregar personaje').last);
    await tester.tap(find.text('Agregar personaje').last);
    await _avanzar(tester, 300);
    expect(
      find.text('Escribe un enlace válido (http o https)'),
      findsOneWidget,
    );

    await tester.enterText(campos.at(5), '');
    await tester.ensureVisible(find.text('Agregar personaje').last);
    await tester.tap(find.text('Agregar personaje').last);
    await _avanzar(tester);
    expect(find.text('Pickle Rick'), findsOneWidget);
    expect(personajes.visibles.first.name, 'Pickle Rick');

    // Eliminar desde el menú de la tarjeta, con confirmación.
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await _avanzar(tester, 500);
    await tester.tap(find.text('Eliminar'));
    await _avanzar(tester, 500);
    expect(find.text('¿Eliminar a Pickle Rick?'), findsOneWidget);
    await tester.tap(find.text('Eliminar').last);
    await _avanzar(tester);
    expect(personajes.visibles.any((c) => c.name == 'Pickle Rick'), isFalse);
  });

  group('catálogo', () {
    test('agregar, editar y eliminar (con deshacer)', () async {
      final (_, c) = await _preparar();
      await c.cargar();
      expect(c.visibles.length, 3);

      final nuevo = await c.agregar(
        const Character(
          id: 0,
          name: 'Pickle Rick',
          status: Estado.alive,
          species: 'Human',
          gender: Genero.male,
          origin: 'Earth',
        ),
      );
      expect(nuevo.esLocal, isTrue);
      expect(c.visibles.first.name, 'Pickle Rick');

      await c.editar(nuevo.copyWith(name: 'Rick Pepinillo'));
      expect(c.porId(nuevo.id)!.name, 'Rick Pepinillo');

      // Un personaje de la API se edita y se elimina solo en el dispositivo.
      final rick = c.porId(1)!;
      await c.editar(rick.copyWith(species: 'Alien'));
      expect(c.porId(1)!.species, 'Alien');

      await c.eliminar(rick);
      expect(c.porId(1), isNull);
      await c.restaurar(rick);
      expect(c.porId(1)!.species, 'Alien');

      await c.eliminar(c.porId(nuevo.id)!);
      expect(c.porId(nuevo.id), isNull);
    });

    test('filtra por nombre, estado y género', () async {
      final (_, c) = await _preparar();
      await c.cargar();

      c.buscar('smith');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(c.visibles.map((e) => e.name), ['Morty Smith', 'Summer Smith']);

      c.filtrar(estado: Estado.dead);
      await Future<void>.delayed(Duration.zero);
      expect(c.visibles.map((e) => e.name), ['Summer Smith']);

      c.filtrar(estado: Estado.dead, genero: Genero.male);
      await Future<void>.delayed(Duration.zero);
      expect(c.visibles, isEmpty);
    });
  });
}
