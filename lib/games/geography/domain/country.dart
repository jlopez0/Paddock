import 'text_match.dart';

enum Continent {
  europa('Europa'),
  asia('Asia'),
  africa('África'),
  america('América'),
  oceania('Oceanía');

  const Continent(this.label);

  final String label;
}

class Country {
  const Country({
    required this.iso,
    required this.name,
    required this.capital,
    required this.continent,
    required this.hasSilhouette,
    this.aliases = const [],
    this.capitalAliases = const [],
  });

  /// Código ISO 3166-1 alfa-2 en minúsculas (nombre del fichero de la bandera).
  final String iso;
  final String name;
  final String capital;
  final Continent continent;
  final bool hasSilhouette;
  final List<String> aliases;
  final List<String> capitalAliases;

  String get flagAsset => 'assets/geo/flags/$iso.svg';

  /// Las ciudades-estado cuya capital se llama igual que el país
  /// (Singapur, Mónaco…) no sirven para preguntas de capitales.
  bool get hasUsableCapital => normalizeText(capital) != normalizeText(name);

  List<String> get acceptedNames => [name, ...aliases];
  List<String> get acceptedCapitals => [capital, ...capitalAliases];

  factory Country.fromJson(Map<String, dynamic> j) => Country(
        iso: (j['iso'] as String).toLowerCase(),
        name: j['nombre'] as String,
        capital: j['capital'] as String,
        continent: Continent.values.byName(j['continente'] as String),
        hasSilhouette: j['silueta'] as bool,
        aliases: (j['alias'] as List?)?.cast<String>() ?? const [],
        capitalAliases: (j['aliasCapital'] as List?)?.cast<String>() ?? const [],
      );
}
