import 'package:flutter/material.dart';

/// Colores disponibles para identificar a cada jugador.
const playerPalette = <Color>[
  Color(0xFFE8B84A),
  Color(0xFFE5575C),
  Color(0xFF4FA3F7),
  Color(0xFF5BC27A),
  Color(0xFFB57BEE),
  Color(0xFFF08A4B),
  Color(0xFF3CC9C0),
  Color(0xFFF06EAA),
];

@immutable
class Player {
  const Player({required this.id, required this.name, required this.colorIndex});

  final String id;
  final String name;
  final int colorIndex;

  Color get color => playerPalette[colorIndex % playerPalette.length];
  String get initial => name.isEmpty ? '?' : name.characters.first.toUpperCase();

  Player copyWith({String? name, int? colorIndex}) =>
      Player(id: id, name: name ?? this.name, colorIndex: colorIndex ?? this.colorIndex);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': colorIndex};

  factory Player.fromJson(Map<String, dynamic> j) =>
      Player(id: j['id'] as String, name: j['name'] as String, colorIndex: j['color'] as int);

  @override
  bool operator ==(Object other) => other is Player && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
