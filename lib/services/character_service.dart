import 'package:dio/dio.dart';

import '../models/character.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CharacterPage {
  const CharacterPage(this.results, {required this.hasMore});

  final List<Character> results;
  final bool hasMore;
}

/// Consulta de personajes en https://rickandmortyapi.com/api/character.
/// La API es de solo lectura: las altas, ediciones y bajas se guardan en
/// el dispositivo (ver `LocalCharacterStore`).
class CharacterService {
  CharacterService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://rickandmortyapi.com/api',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _dio;

  /// Reintentos automáticos ante fallos pasajeros (la API limita las ráfagas
  /// de peticiones y responde sin conexión durante unos segundos).
  static const _reintentos = 3;

  Future<CharacterPage> buscar({
    int page = 1,
    String name = '',
    Estado? status,
    Genero? gender,
  }) async {
    for (var intento = 0; ; intento++) {
      try {
        final r = await _dio.get<Map<String, dynamic>>(
          '/character',
          queryParameters: {
            'page': page,
            if (name.isNotEmpty) 'name': name,
            if (status != null) 'status': status.api,
            if (gender != null) 'gender': gender.api,
          },
        );
        final data = r.data!;
        return CharacterPage([
          for (final c in data['results'] as List)
            Character.fromApi(c as Map<String, dynamic>),
        ], hasMore: (data['info'] as Map)['next'] != null);
      } on DioException catch (e) {
        // Sin coincidencias la API responde 404.
        if (e.response?.statusCode == 404) {
          return const CharacterPage([], hasMore: false);
        }
        if (intento < _reintentos && _esPasajero(e)) {
          await Future<void>.delayed(_espera(e, intento));
          continue;
        }
        throw ApiException(switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.sendTimeout => 'El servidor tardó demasiado',
          DioExceptionType.connectionError => 'Sin conexión a internet',
          _ => 'No se pudieron cargar los personajes',
        });
      }
    }
  }

  /// Respeta `Retry-After` si la API lo envía; si no, espera cada vez más.
  Duration _espera(DioException e, int intento) {
    final segundos = int.tryParse(
      e.response?.headers.value('retry-after') ?? '',
    );
    return Duration(seconds: (segundos ?? 1 + intento).clamp(1, 10));
  }

  bool _esPasajero(DioException e) {
    final codigo = e.response?.statusCode;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        codigo == 429 ||
        (codigo != null && codigo >= 500);
  }
}
