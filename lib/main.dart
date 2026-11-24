import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_info.dart';
import 'app/licenses.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/audio/app_sound.dart';
import 'core/settings/settings_controller.dart';
import 'core/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerExtraLicenses();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PaddockApp(),
    ),
  );
  // Sin bloquear el arranque: evita el retardo del primer sonido.
  unawaited(preloadSounds());
}

class PaddockApp extends ConsumerWidget {
  const PaddockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      settingsProvider,
    ); // carga los ajustes (sonido/vibración) al arrancar
    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
