# Paddock: plan de cambios para publicar (v1.0)

Objetivo: que la app pase la revisión de Google Play y del App Store a la primera y que aporte valor más allá de "app para beber". Prioridad actual: **Google Play** (prueba cerrada antes del 1/12); Apple, a partir de enero.

Idea central: **Paddock es un recopilatorio de juegos de grupo con marcador de la noche. Beber es solo un modo opcional de consecuencias, nunca el núcleo.**

> **Estado (19/11/2026)**
> - Fase 0, configuración hecha: IDs `es.jlopez0.paddock`, compileSdk/targetSdk 36, firma release con `key.properties`, `PrivacyInfo.xcprivacy`, `ITSAppUsesNonExemptEncryption=false`, solo iPhone, versión 1.0.0+1, `docs/` (privacidad, soporte, guía Android).
> - Fase 0, hecha en código (20/11/2026): pantalla de Ajustes (sonido, vibración, privacidad, soporte, créditos, versión; el modo de consecuencias queda como hueco para la Fase 1), nombre en `kAppName`, SafeArea en las pantallas de lista y atrás predictivo activado, paquetes actualizados, AAB release compilado.
> - Fase 0, pendiente a mano: probar en emulador Android 16; sustituir `CORREO_DE_CONTACTO` y activar GitHub Pages; generar la clave de subida; `flutter upgrade` (bloqueado por Device Guard, SDK en 3.41.5); `codemagic.yaml` (cuando toque iOS).

Bloqueos detectados en el punto de partida (commit 644b0a1):
- 186 de las 329 frases de "Yo nunca" son "hot" explícitas.
- En la carrera se apuestan de 1 a 10 tragos, más el "hidalgo" (vaso entero): es el "competition/binge drinking" que prohíben las dos tiendas.
- Apple 4.3(b) cita los "drinking games" como spam.

---

## Fase 0 · Base técnica de publicación
Modelo: **Sonnet 5.5 · esfuerzo medio**

1. ✅ IDs definitivos `es.jlopez0.paddock` (no se pueden cambiar después de publicar).
2. ✅ `pubspec.yaml`: description y versión `1.0.0+1`. ✅ Plugins actualizados (`flutter pub upgrade`; `audioplayers_android` fijado a 5.2.1 por incompatibilidad con AGP 8.11). ⏳ `flutter upgrade`: Device Guard bloquea el `dart.exe` nuevo (3.50); SDK vuelto a 3.41.5.
3. ✅ Android: compileSdk/targetSdk 36 y firma release con `key.properties`. ✅ SafeArea en todas las pantallas y `enableOnBackInvokedCallback`. ⏳ Probar en un emulador con Android 16.
4. ✅ iOS: `PrivacyInfo.xcprivacy`, `ITSAppUsesNonExemptEncryption=false`, solo iPhone.
5. ⏳ `codemagic.yaml` (cuando toque iOS).
6. ✅ `docs/` para GitHub Pages. ⏳ Poner el correo y activar Pages.
7. ✅ Pantalla **Ajustes**: modo de consecuencias, sonido, vibración, privacidad, soporte, créditos y versión.

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
