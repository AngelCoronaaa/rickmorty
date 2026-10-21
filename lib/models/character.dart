import 'package:flutter/material.dart';

/// Valores que usa la API (en inglés) con su etiqueta en español.
enum Estado {
  alive('Alive', 'Vivo', Color(0xFF3DDC84)),
  dead('Dead', 'Muerto', Color(0xFFFF5470)),
  unknown('unknown', 'Desconocido', Color(0xFF9AA3B2));

  const Estado(this.api, this.etiqueta, this.color);

  final String api;
  final String etiqueta;
  final Color color;

  static Estado desde(String? valor) => values.firstWhere(
    (e) => e.api.toLowerCase() == valor?.toLowerCase(),
    orElse: () => unknown,
  );
}

enum Genero {
  female('Female', 'Femenino', Icons.female_rounded),
  male('Male', 'Masculino', Icons.male_rounded),
  genderless('Genderless', 'Sin género', Icons.transgender_rounded),
  unknown('unknown', 'Desconocido', Icons.help_outline_rounded);

  const Genero(this.api, this.etiqueta, this.icono);

  final String api;
  final String etiqueta;
  final IconData icono;

  static Genero desde(String? valor) => values.firstWhere(
    (g) => g.api.toLowerCase() == valor?.toLowerCase(),
    orElse: () => unknown,
  );
}

/// Personaje de la serie. Los creados en la app tienen [id] negativo.
@immutable
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.gender,
    required this.origin,
    this.type = '',
    this.location = '',
    this.image = '',
    this.episodes = 0,
  });

  final int id;
  final String name;
  final Estado status;
  final String species;
  final Genero gender;
  final String origin;
  final String type;
  final String location;
  final String image;
  final int episodes;

  /// Creado por el usuario (no existe en la API).
  bool get esLocal => id < 0;

  factory Character.fromApi(Map<String, dynamic> json) => Character(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    status: Estado.desde(json['status'] as String?),
    species: json['species'] as String? ?? '',
    type: json['type'] as String? ?? '',
    gender: Genero.desde(json['gender'] as String?),
    origin: (json['origin'] as Map?)?['name'] as String? ?? 'unknown',
    location: (json['location'] as Map?)?['name'] as String? ?? '',
    image: json['image'] as String? ?? '',
    episodes: (json['episode'] as List?)?.length ?? 0,
  );

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json['id'] as int,
    name: json['name'] as String,
    status: Estado.desde(json['status'] as String?),
    species: json['species'] as String,
    type: json['type'] as String? ?? '',
    gender: Genero.desde(json['gender'] as String?),
    origin: json['origin'] as String,
    location: json['location'] as String? ?? '',
    image: json['image'] as String? ?? '',
    episodes: json['episodes'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status.api,
    'species': species,
    'type': type,
    'gender': gender.api,
    'origin': origin,
    'location': location,
    'image': image,
    'episodes': episodes,
  };

  Character copyWith({
    int? id,
    String? name,
    Estado? status,
    String? species,
    Genero? gender,
    String? origin,
    String? type,
    String? location,
    String? image,
  }) => Character(
    id: id ?? this.id,
    name: name ?? this.name,
    status: status ?? this.status,
    species: species ?? this.species,
    gender: gender ?? this.gender,
    origin: origin ?? this.origin,
    type: type ?? this.type,
    location: location ?? this.location,
    image: image ?? this.image,
    episodes: episodes,
  );
}
