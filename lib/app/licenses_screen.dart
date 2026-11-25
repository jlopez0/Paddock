import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_icons.dart';
import 'theme.dart';

/// Licencias de un paquete: todas las entradas del `LicenseRegistry` que lo citan.
class PackageLicenses {
  const PackageLicenses(this.name, this.entries);

  final String name;
  final List<LicenseEntry> entries;

  int get count => entries.length;
}

/// Lee el `LicenseRegistry` entero y agrupa por paquete (orden alfabético).
/// Un colector que falle no impide ver el resto.
Future<List<PackageLicenses>> loadPackageLicenses({
  Stream<LicenseEntry>? source,
}) async {
  final byPackage = <String, List<LicenseEntry>>{};
  await for (final entry in (source ?? LicenseRegistry.licenses).handleError(
    (Object _) {},
  )) {
    for (final package in entry.packages) {
      (byPackage[package] ??= []).add(entry);
    }
  }
  final names = byPackage.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [for (final n in names) PackageLicenses(n, byPackage[n]!)];
}

String _licenseCount(int n) => n == 1 ? '1 licencia' : '$n licencias';

ShapeBorder _brassShape() => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(14),
  side: BorderSide(color: AppColors.brass.withValues(alpha: 0.6)),
);

/// Licencias de software en español y con el estilo de la casa. Sustituye a
/// `showLicensePage` (en inglés y con otro tema).
class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key, this.loader});

  /// Solo para tests: sustituye la lectura del `LicenseRegistry`.
  @visibleForTesting
  final Future<List<PackageLicenses>> Function()? loader;

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late final Future<List<PackageLicenses>> _packages =
      (widget.loader ?? loadPackageLicenses)();
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final v = (await PackageInfo.fromPlatform()).version;
      if (mounted) setState(() => _version = v);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Licencias')),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<PackageLicenses>>(
          future: _packages,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final packages = snapshot.data ?? const <PackageLicenses>[];
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: packages.isEmpty ? 2 : packages.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _Header(version: _version, total: packages.length);
                }
                if (packages.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay licencias registradas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                final p = packages[i - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PackageTile(package: p),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.version, required this.total});

  final String version;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              version.isEmpty ? 'Paddock' : 'Paddock $version',
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 22,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'Paddock funciona sin conexión y sin enviar datos a ningún sitio.'
                : 'Paddock usa $total paquetes y recursos de código abierto. '
                      'Toca uno para leer sus licencias; los textos legales '
                      'se muestran en su idioma original.',
            style: const TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.package});

  final PackageLicenses package;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      container: true,
      label: '${package.name}, ${_licenseCount(package.count)}',
      child: ExcludeSemantics(
        child: Material(
          color: AppColors.surface,
          shape: _brassShape(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PackageLicenseScreen(package: package),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Stack(
                children: [
                  // Filete de latón del boleto.
                  const Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 5,
                    child: ColoredBox(color: AppColors.brass),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(19, 10, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                package.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _licenseCount(package.count),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppIcon.chevronRight.widget(size: 22),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Texto completo de las licencias de un paquete.
class PackageLicenseScreen extends StatelessWidget {
  const PackageLicenseScreen({super.key, required this.package});

  final PackageLicenses package;

  @override
  Widget build(BuildContext context) {
    final entries = package.entries;
    final items = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
        child: Semantics(
          header: true,
          child: Text(
            package.name,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 22,
              color: AppColors.gold,
              height: 1.2,
            ),
          ),
        ),
      ),
      for (var e = 0; e < entries.length; e++) ...[
        if (entries.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Semantics(
              header: true,
              child: Text(
                'Licencia ${e + 1} de ${entries.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brass,
                ),
              ),
            ),
          ),
        Container(height: 1, color: AppColors.brass.withValues(alpha: 0.6)),
        for (final paragraph in entries[e].paragraphs)
          Padding(
            padding: EdgeInsets.fromLTRB(
              4 + (paragraph.indent > 0 ? paragraph.indent * 12.0 : 0),
              8,
              4,
              0,
            ),
            child: Text(
              paragraph.text,
              textAlign: paragraph.indent == LicenseParagraph.centeredIndent
                  ? TextAlign.center
                  : TextAlign.start,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.text,
              ),
            ),
          ),
      ],
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Licencia')),
      body: SafeArea(
        top: false,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: items.length,
          itemBuilder: (_, i) => items[i],
        ),
      ),
    );
  }
}
