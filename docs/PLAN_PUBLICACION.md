# Paddock: plan de cambios para publicar (v1.0)

Objetivo: que la app pase la revisión de Google Play y del App Store a la primera y que aporte valor más allá de "app para beber". Prioridad actual: **Google Play** (prueba cerrada antes del 1/12); Apple, a partir de enero.

Idea central: **Paddock es un recopilatorio de juegos de grupo con marcador de la noche. Beber es solo un modo opcional de consecuencias, nunca el núcleo.**

> **Estado (19/11/2026)**
> - Fase 0, configuración hecha: IDs `es.jlopez0.paddock`, compileSdk/targetSdk 36, firma release con `key.properties`, `PrivacyInfo.xcprivacy`, `ITSAppUsesNonExemptEncryption=false`, solo iPhone, versión 1.0.0+1, `docs/` (privacidad, soporte, guía Android).
> - Fase 0, hecha en código (20/11/2026): pantalla de Ajustes (sonido, vibración, privacidad, soporte, créditos, versión; el modo de consecuencias queda como hueco para la Fase 1), nombre en `kAppName`, SafeArea en las pantallas de lista y atrás predictivo activado, paquetes actualizados, AAB release compilado.
> - Fase 0, geografía: confirmación al salir (atrás predictivo) en la partida, como Trivia, Rosco y Carrera (24/11/2026).
> - Fase 0, pendiente a mano: probar en emulador Android 16; sustituir `CORREO_DE_CONTACTO` y activar GitHub Pages; generar la clave de subida; `codemagic.yaml` (cuando toque iOS).

Bloqueos detectados en el punto de partida (commit 644b0a1):
- 186 de las 329 frases de "Yo nunca" son "hot" explícitas.
- En la carrera se apuestan de 1 a 10 tragos, más el "hidalgo" (vaso entero): es el "competition/binge drinking" que prohíben las dos tiendas.
- Apple 4.3(b) cita los "drinking games" como spam.

---

## Fase 0 · Base técnica de publicación
Modelo: **Sonnet 5.5 · esfuerzo medio**

1. ✅ IDs definitivos `es.jlopez0.paddock` (no se pueden cambiar después de publicar).
2. ✅ `pubspec.yaml`: description y versión `1.0.0+1`. ✅ Plugins actualizados (`flutter pub upgrade`; `audioplayers_android` fijado a 5.2.1 por incompatibilidad con AGP 8.11). ✅ `flutter upgrade` (Flutter 3.50.1, Dart 3.14, Gradle 9.3.1, AGP 9.1.1, `material_ui`). Con Device Guard hay que compilar con `--no-tree-shake-icons` (bloquea `font-subset.exe`).
3. ✅ Android: compileSdk/targetSdk 36 y firma release con `key.properties`. ✅ SafeArea en todas las pantallas y `enableOnBackInvokedCallback`. ✅ Probado en emulador Android 16 (API 36.1): home, Ajustes, Geografía (con confirmación al salir) y Rosco sin contenido bajo las barras; faltan por revisar a mano Carrera, Trivia y Yo nunca.
4. ✅ iOS: `PrivacyInfo.xcprivacy`, `ITSAppUsesNonExemptEncryption=false`, solo iPhone.
5. ⏳ `codemagic.yaml` (cuando toque iOS).
6. ✅ `docs/` para GitHub Pages. ⏳ Poner el correo y activar Pages.
7. ✅ Pantalla **Ajustes**: sonido, vibración, privacidad, soporte, créditos y versión (el modo de consecuencias entra en la Fase 1).

## Fase 1 · Sistema de consecuencias (el "enmascarado" del alcohol)
Modelo: **Opus 5.5 · esfuerzo medio**

Toda la app habla en **fichas**. Al empezar la sesión se elige cómo se "pagan":

| Modo | Por defecto | Qué significa perder X fichas |
|---|---|---|
| 🏆 Puntos | Sí | Se restan del marcador de la noche (Fase 3) |
| 🎭 Retos | | Al final de la ronda, un reto por cada ficha perdida (máx. 3) |
| 🥤 Sorbos (opcional) | Desactivado; se activa en Ajustes con confirmación +18 | 1 ficha = 1 sorbo, tope 3 por ronda, "cambiar por agua o reto" siempre visible |

- `bets.dart`: apostar fichas (1–5); "hidalgo" → "All-in".
- Textos: "Palo y tragos" → "Palo y fichas"; "¿Quién bebe?" → "¿Quién paga?"; "🍺 Beben" → "Pagan"; "¡A beber todos!" → "¡Todos pagan!"; "bebidos" → "fichas perdidas".
- Yo nunca: "Quien lo haya hecho, pierde una ficha"; subtítulo "Confiesa… o paga".
- Widget `ConsequenceBanner` que traduce fichas al modo activo.
- Mazo de retos (`retos.json`, ~80) sin riesgo físico ni alcohol.
- Bienvenida la primera vez: "+18 · Juega con responsabilidad · Nadie está obligado a beber", con enlace a privacidad.

## Fase 2 · Contenido
Modelo: **Opus 5.5 · esfuerzo medio**

1. Niveles: Suave 😇 · Picante 🌶️ · Atrevido 🔥 (desactivado por defecto, con confirmación +18).
2. Reescribir las 186 "hot" en tono sugerente, no explícito (~120 buenas).
3. Quitar "borracho" y frases que celebren emborracharse.
4. Ampliar Suave de 26 a ~100.
5. `content_test.dart` con lista negra de palabras.
6. Trivia: marcar las preguntas de Open Trivia DB (CC BY-SA 4.0) y atribuir.

## Fase 3 · Más valor: la Copa y juegos nuevos
Modelo: **Sonnet 5.5 · esfuerzo alto**

- **Copa Paddock**: `SessionScoreController`, clasificación en la home, podio final con estadísticas y "Compartir resultado" (`share_plus`).
- **El Infiltrado** (impostor), **¿Quién es más probable…?**, reactivar **¿Qué preferirías?** (45 → ~120). v1.1: Patata caliente.
- Menú: Carrera · Infiltrado · Trivia · Geografía · Abecedario · ¿Quién es más probable? · ¿Qué preferirías? · Yo nunca.

## Fase 4 · Rosco → Abecedario
Modelo: **Sonnet 5.5 · esfuerzo medio**

- Renombrar todo a "Abecedario"; cero menciones a "Rosco"/"Pasapalabra".
- Cuadrícula A–Z o tarjetas en lugar del círculo; temporizador por equipos.
- Verificar que las 330 definiciones son propias.

## Fase 5 · Pulido
Modelo: **Sonnet 5.5 · esfuerzo medio**

- "¿Cómo se juega?" en cada juego; vibración y sonidos con interruptor; accesibilidad (escala de texto, contraste, `Semantics`); orientación controlada; estados vacíos; icono y splash finales; i18n con ARB; más tests y `flutter analyze` limpio.

## Fase 6 · Ficha de tienda y capturas
Modelo: **Sonnet 5.5 · esfuerzo bajo**

- "Paddock: Juegos de fiesta" / "Carreras, trivia y retos en grupo".
- Capturas automatizadas (Carrera → Copa → Infiltrado → Geografía → Trivia), sin "Atrevido" ni alcohol.
- Notas para el revisor de Apple en inglés; cuestionarios: Apple 18+, PEGI 16–18.

---

## Cómo usarlo en Claude Code
```
Lee docs/PLAN_PUBLICACION.md y SPEC.md. Ejecuta solo la Fase N.
Antes de tocar código, dime en 5 líneas qué vas a cambiar y espera mi OK.
Commits pequeños; pasa `flutter analyze` y `flutter test` antes de cada commit.
Al terminar, marca la fase como hecha en el plan y apunta las decisiones tomadas.
```

## Estado de las fases (24/11/2026)
- ✅ Fase 0 (salvo tareas manuales de Javier: correo y Pages, clave de subida, pruebas en emulador).
- ✅ Fase 1: fichas, modos Puntos/Retos/Sorbos (+18), `ConsequenceBanner`, bienvenida +18, Carrera con All-in (10 fichas), guardia anti-alcohol.
- ✅ Fase 2: niveles Suave/Picante/Atrevido, contenido reescrito, test de lista negra, atribución de Open Trivia DB.
- ✅ Fase 3: Copa Paddock, El Infiltrado, ¿Quién es más probable?, ¿Qué preferirías? (120). Falta 3.11 (Trivia y Geografía → Copa), opcional, para v1.1.
- ✅ Fase 4: Abecedario (cuadrícula A–Z). No se hizo el temporizador por equipos (decisión de diseño pendiente).
- ✅ Fase 5: "¿Cómo se juega?" en los 8 juegos, accesibilidad (tooltips, letra al doble sin desbordes, estados vacíos y de error), orientación, copia de seguridad de Android desactivada, licencias en Créditos. i18n con ARB aplazado a la v1.1 (la v1 sale solo en español).
- ✅ Fase 6, textos: ficha, notas para el revisor de Apple, cuestionarios y lista de pasos de Google Play en `docs/store/`; informe de cumplimiento en `docs/COMPLIANCE.md`. ⏳ Capturas de pantalla (necesitan emulador) y revisar los ❓ de los cuestionarios con los formularios reales.

## Rediseño con alma (rama `diseno-alma`, 25/11/2026)
- Rama aparte de `fase-0-publicacion` (versión publicable previa al rediseño, intacta). Sin fusionar con `main`.
- Dirección: "casa de apuestas de hipódromo de los años 30 de noche". Alfa Slab One + Figtree, iconos Phosphor duotono tras `AppIcon`, ficha, boleto, medalla, Jockey y trofeo dibujados por código, sin emojis ni `Icons` de Material (vigilado por `no_emoji_test`), microcopy con voz propia, 7 sonidos CC0 de Kenney y animaciones que respetan `disableAnimations` y el ajuste de vibración.
- Detalle en `docs/DISENO_ALMA.md`, `docs/MICROCOPY.md`, `docs/COMPLIANCE.md` y `docs/decisions.md`.
- Pendiente de Javier: oír `correct`, `wrong` y `podium`; probar la Carrera en móvil físico; comprobar en un build real que `confetti` no sale duplicada en Licencias; enlazar en Créditos las páginas de autoría de la baraja que faltan.

## Bitácora del jefe
- 2026-11-25 · Rediseño · jefe + arquitecto de recursos, implementador, juego-flutter, redactor-es, cumplimiento, revisor · 2 rondas de QA visual en emulador Android 16 (sin bloqueantes en la 2.ª), revisión final LISTO, 426 tests en verde y `flutter analyze` limpio · APK release 64,4 MB.
- 2026-11-24 · Fase 0 · jefe · commit del estado y 4 tareas manuales en Todoist.
- 2026-11-24 · Fase 4 · implementador, redactor-es, revisor · Abecedario hecho y revisado (LISTO) → commits 841ddbf y 28e1f47.
- 2026-11-24 · Fases 1–3 · arquitecto (desglose en docs/FASES_1_3.md), implementador, juego-flutter, contenido-fiesta, mecanico, redactor-es · 2 revisiones; la 1.ª encontró 1 bloqueante (retos atrevidos sin +18), corregido en la 1.ª vuelta; la 2.ª dio LISTO · 216 tests en verde y `flutter analyze` limpio → commits 6a35abe, b1839d1, 7317722 y a2e6b94.
- 2026-11-24 · Fases 5 y 6 · redactor-es, release-movil, cumplimiento, implementador, mecanico, revisor · revisión LISTO (230 tests, `flutter analyze` limpio, APK de depuración compila). AAB release compila pero va firmado con clave de depuración: falta la clave de subida (tarea de Javier). El cuestionario IARC corregido: alcohol "Sí" por el modo Sorbos.
- Decisiones del dueño: unidad "fichas"; All-in = 10 fichas; el All-in ganador reparte 2 All-in a 2 personas distintas.
- Pendiente de confirmar: que el ganador de un All-in sume +10 por cada persona elegida (supuesto D11).
- 2026-11-24 · Diseño con alma, zona Carrera (`lib/games/horse_race/**`) · ✅ sin emoji; fichas dibujadas con caída al apostar (All-in = ficha especial de 10); resultado en boletos con sello COBRA/PAGA; "¡GANA!" en Alfa Slab One; medallas en podio y ranking; confeti solo con ganador; `disableAnimations` y vibración respetados; microcopy aplicado. Tests: `race_chips_test.dart` actualizado y `race_design_test.dart` nuevo.
- 2026-11-24 · Diseño con alma, zona Copa y Créditos (`lib/app/cup_screen.dart`, `credits_screen.dart`) · ✅ podio sobre fondo burdeos con trofeo y Jockey; medallas `MedalIcon` que caen una a una con rebote, háptico (respeta Vibración) y confeti `confetti` (nada con `disableAnimations`); 🏆 solo en `kShareTrophy` (texto compartido; las medallas del texto ahora son "1.", "2."); microcopy de Copa aplicado ("Va en cabeza", "El que más ha pagado", "Compartir la Copa"); Créditos con sección "Diseño" (Phosphor MIT, Alfa Slab One y Figtree OFL, confetti MIT) y línea de cortesía Kenney CC0. Tests: `cup_screen_test.dart` ampliado y `credits_screen_test.dart` nuevo.
