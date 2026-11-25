import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licencias de fuentes y paquetes de diseño que Flutter no recoge solo.
const _extraLicenses = <(List<String>, String)>[
  (['Alfa Slab One (fuente)'], 'assets/licenses/AlfaSlabOne-OFL.txt'),
  (['Figtree (fuente)'], 'assets/licenses/Figtree-OFL.txt'),
  (['Phosphor Icons (fuentes de iconos)'], 'assets/licenses/Phosphor-MIT.txt'),
  (['confetti'], 'assets/licenses/confetti-MIT.txt'),
];

/// Registra las licencias extra en la pantalla de licencias de Flutter.
/// Llamar una vez al arrancar, antes de `runApp`.
void registerExtraLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (packages, asset) in _extraLicenses) {
      final text = await rootBundle.loadString(asset);
      yield LicenseEntryWithLineBreaks(packages, text);
    }
  });
}
