# Estado de publicación de Paddock (2026-11-26)

Solo lectura del repo, sin ejecutar nada de Flutter. Leyenda: ✅ listo · ⚠️ a medias · ❌ falta · ❓ no verificado.

## 1. Estado real por requisito

| Requisito | Google Play | App Store |
|---|---|---|
| ID | ✅ `es.jlopez0.paddock` (namespace interno `com.paddock.paddock`, a propósito) | ✅ `es.jlopez0.paddock` en Runner (RunnerTests `.RunnerTests`). ❓ Bundle ID aún no registrado en Apple Developer |
| Versión | ✅ `1.0.0+1` (pubspec). Subir `+build` en cada subida | ✅ igual (usa `$(FLUTTER_BUILD_NUMBER)`) |
| Firma release | ❌ No existe `android/key.properties`: el AAB sale firmado con **clave debug** y Play lo rechaza. El gradle ya lo soporta y está ignorado por git (verificado) | ❌ Sin `codemagic.yaml`, sin certificados ni perfil. Cuenta Apple ❓ |
| Artefacto | ⚠️ `app-release.aab` (66 MB) es del 25/11 09:20: anterior al último rediseño y a la opción C de la Copa. Hay que recompilarlo | ❌ Sin build iOS. Hay `Paddock-ipa*` en la raíz del repo: ❓ no sé qué son ni si están en git |
| SDK / target | ✅ compileSdk 36, targetSdk 36, minSdk 24 (el comentario del gradle cita API 36 obligatoria desde 31/08/2026; ❓ no re-verificado hoy en la doc de Google) | ✅ Deployment target 13.0, solo iPhone (`TARGETED_DEVICE_FAMILY=1`) |
| Android 15/16 | ✅ `enableOnBackInvokedCallback`, SafeArea, probado en emulador API 36.1 (faltan a mano Carrera, Trivia, Yo nunca) | ➖ |
| PrivacyInfo / cifrado | ➖ | ✅ `PrivacyInfo.xcprivacy` (UserDefaults CA92.1, sin tracking ni datos) e `ITSAppUsesNonExemptEncryption=false` |
| Política de privacidad y soporte | ❌ `https://jlopez0.github.io/Paddock/privacidad.html` devuelve **404** (Pages sin activar o repo privado) y `privacidad.html`/`soporte.html` aún tienen `CORREO_DE_CONTACTO` | ❌ idem (Apple exige URL de privacidad y de soporte) |
| Ficha | ✅ textos en `docs/store/ficha_es.md`; gráficos 512 y 1024x500 listos | ✅ textos y notas de revisor en inglés (`notas_revisor_apple_en.md`). ⚠️ reescribir si iOS sale sin Sorbos |
| Capturas | ⚠️ 8 en `docs/store/capturas/`; `01_home.png` es anterior a D14 y hay que rehacerla (modo Fichas, sin Sorbos) | ❌ Sin capturas en tamaños de iPhone exigidos (❓ comprobar medidas actuales en App Store Connect) |
| Cuestionarios | ⚠️ IARC redactado en `cuestionarios.md` (alcohol Sí, azar simulado Sí, sexualidad sugerida Sí; PEGI 16-18). Falta rellenar el formulario real | ⚠️ borrador Apple 18+; decidir frecuencia de azar simulado (R3). Sin Sorbos cambian las respuestas de alcohol: revisar |
| Data safety | ⚠️ respuesta preparada: no recopila ni comparte. Rellenar y comprobar AD_ID/permisos con el AAB subido (manifest fusionado sin INTERNET ni AD_ID, verificado 25/11) | ➖ Nutrition label: "Datos no recopilados" ❓ |
| Cuenta de desarrollador | ❓ Sin evidencia de que exista (25 USD). Cuenta personal: prueba cerrada con 12+ testers, 14 días seguidos | ❓ Apple Developer (99 USD/año) sin evidencia |
| Calidad | ⚠️ `flutter analyze` limpio según la bitácora; **`flutter test` no se puede ejecutar en esta máquina** (Code Integrity bloquea `flutter_tester.exe`). Último verde conocido: 426 tests el 25/11, antes de la opción C | idem |
| Git | ⚠️ ~68 archivos modificados sin commit (rediseño y Copa C) | idem |

Plazo: la prueba cerrada era "antes del 1/12". Con la clave de subida y Pages sin hacer, el calendario es muy justo: 14 días de prueba solo empiezan cuando haya 12 testers dentro.

## 2. Compilar iOS sin modo Sorbos (recomendación de `cumplimiento_copa.md` y COMPLIANCE #3)

Propuesta: un `dart-define` con valor por defecto true (Android no cambia).
- Nuevo `const bool kSorbosEnabled = bool.fromEnvironment('SORBOS', defaultValue: true);` (p. ej. en `lib/core/consequences/consequences.dart`).
- iOS: `flutter build ipa --dart-define=SORBOS=false` (en `codemagic.yaml`). Android: sin flag.

Archivos que tocaría (hay 37 referencias a "sorbos/beber" fuera de `core/consequences`):
- `lib/core/consequences/consequences.dart`, `consequence_banner.dart`, `consequence_mode_selector.dart`: el selector solo ofrece Fichas y Retos; `modes` sin `sorbos`.
- `lib/core/settings/settings_controller.dart`: `setMode(sorbos)` no hace nada y un valor guardado `sorbos` cae a puntos. Con flag off, tampoco hace falta el diálogo +18 de Sorbos (el +18 de Atrevido se queda).
- `lib/app/home_screen.dart`, `settings_screen.dart`, `welcome_screen.dart` (línea 101 "Nadie está obligado a beber") y `credits_screen.dart` (línea 208): textos condicionales, sin mención a beber.
- Juegos: `horse_race/race_texts.dart`, `ui/race_widgets.dart`, `ui/race_result_screen.dart`, `infiltrado/ui/infiltrado_setup_screen.dart`, `prompt_deck/prompt_deck_logic.dart`, `prompt_deck_module.dart`, `prompt_deck_screens.dart`.
- `assets/content/es/ayuda.json` (líneas 68 y 90 citan Sorbos): necesita variante o filtro en runtime.
- Tests: `test/` con guardia que pruebe ambos valores (`flutter test --dart-define=SORBOS=false`) y añadir a `no_emoji_test`-style un test que falle si aparece "sorbo/beb" con el flag apagado.
- Docs: ficha iOS, `cuestionarios.md` (alcohol "No" en Apple solo si de verdad no queda ninguna referencia: comprobar texto de Atrevido y "borracho" en la lista negra), notas del revisor.

Esfuerzo: medio día a 1 día (juego-flutter + revisor). Riesgo: que quede algún texto suelto; el test de cadenas lo cubre. Hasta decidirlo, no enviar a revisión de Apple (según COMPLIANCE).

## 3. Quién hace qué

Manual de Javier (cuentas, pagos, formularios):
1. **Correo y Pages.** Elegir correo público; sustituir `CORREO_DE_CONTACTO` en `docs/privacidad.html` y `soporte.html` (un agente puede editar si dices el correo). En GitHub: repo Paddock, Settings > Pages, rama `main`, carpeta `/docs`. Si el repo es privado, Pages exige plan de pago o hacerlo público (❓ cuál es tu caso). Comprobar que la URL abre.
2. **Clave de subida.** Seguir `docs/PUBLICAR_ANDROID.md`: `keytool -genkeypair ...` (PowerShell), crear `android/key.properties` con las 4 claves, guardar keystore y contraseñas en un gestor (si se pierde, solo recupera Google vía soporte). Nunca a git.
3. **Cuenta Play Console** (25 USD, verificación de identidad); declarar "no comerciante" si no cobras.
4. **Rellenar Play Console**: Contenido de la app (política, anuncios No, acceso, público 18+, IARC, Data safety) con `CHECKLIST_GOOGLE_PLAY.md` y `cuestionarios.md`.
5. **Prueba cerrada**: reunir 12+ testers (Gmail o Google Group), compartir el enlace, que no desinstalen 14 días. Dar el OK explícito antes de enviar.
6. **Apple** (a partir de enero): Apple Developer, registrar el Bundle ID, crear la app en App Store Connect, clave de API de App Store Connect para Codemagic, cuestionario de edad, DSA.
7. **Capturas**: rehacer `01_home.png` en emulador; capturas de iPhone para Apple. Oír `correct.wav`/`wrong.wav`/`podium` y probar Carrera en móvil real (pendientes de la bitácora).
8. Decidir A/B y aceptar Sorbos fuera de la home (cumplimiento_copa, punto 2).

Agente (con tu OK para enviar nada a tiendas):
- Recompilar AAB firmado y verificar firma/manifest (`habin:release-movil`).
- Flag Sorbos para iOS, tests y textos (`juego-flutter`, `habin:revisor`).
- Escribir `codemagic.yaml` sin secretos (referencias a variables de entorno de Codemagic) (`habin:release-movil`).
- Actualizar ficha, notas de Apple y cuestionarios (`habin:redactor-es`, `habin:cumplimiento`).
- Commits del estado actual, `flutter analyze` y registrar decisiones.

## 4. Qué falta para la versión final (priorizado)

| # | Tarea | Esfuerzo | Quién |
|---|---|---|---|
| 1 | Ejecutar `flutter test` en otra máquina o CI y commitear el estado (68 archivos sin commit) | 1 h | Javier (máquina) + `habin:revisor` |
| 2 | Correo + activar Pages + comprobar URLs (bloquea Play y Apple) | 20 min | Javier; agente edita HTML |
| 3 | Generar clave de subida y `key.properties` | 20 min | Javier |
| 4 | Recompilar AAB release con `--no-tree-shake-icons` y confirmar firma de subida | 30 min | `habin:release-movil` |
| 5 | Cuenta Play Console y verificación | 1-3 días de espera | Javier |
| 6 | Rehacer `01_home.png`, revisar Carrera/Trivia/Yo nunca en emulador | 1 h | Javier + agente |
| 7 | Formularios Play (IARC, Data safety, público) y prueba cerrada con 12 testers | 2 h + 14 días | Javier |
| 8 | Flag `SORBOS=false` para iOS | 0,5-1 día | `juego-flutter` + `habin:revisor` |
| 9 | `codemagic.yaml` y firma iOS | 0,5 día + cuenta Apple | `habin:release-movil` + Javier |
| 10 | Capturas iPhone, ficha y cuestionario Apple (sin alcohol) | 0,5 día | `habin:redactor-es` + Javier |
| 11 | Pendientes menores: origen de TTF Phosphor (R1), renombrar entrada de licencia (R4), búsqueda TMview de "Paddock" | 1-2 h | `habin:cumplimiento` / Javier |
| 12 | Revisión legal opcional del Abecedario (riesgo aceptado por el dueño) | ❓ | profesional |

Ruta crítica Android: 2 > 3 > 4 > 5 > 7. Sin tareas 2 y 3 no se puede abrir la prueba cerrada.
