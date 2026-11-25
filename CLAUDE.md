# Paddock

Recopilatorio de juegos de fiesta en Flutter, solo en español. Las reglas comunes de Javier y el equipo de agentes (`habin:*`) llegan por el plugin `habin`; aquí solo lo propio de Paddock.

## Restricciones duras
- 100 % offline: sin red, analítica, anuncios ni cuentas. Los datos no salen del dispositivo (copia de seguridad de Android desactivada a propósito).
- Beber es un modo opcional, nunca el núcleo. Toda la app habla en **fichas**; los sorbos solo con `adultConfirmed` (+18), tope de 3 por ronda y alternativa de agua o reto siempre visible.
- Cada juego implementa `GameModule` en `lib/games/<juego>/` y se registra en `lib/games/registry.dart`.
- Sin emojis ni `Icons` de Material en la UI: iconos con `AppIcon` (lo vigila `no_emoji_test`).
- Contenido propio o con licencia verificada; lo no verificado se marca en `assets/CREDITS.md`, no se inventa. Nada de "Rosco"/"Pasapalabra".
- ID de app `es.jlopez0.paddock`: no se cambia tras publicar. El formato `session.v1` solo cambia con una clave `.v2` y migración.
- Android: compilar con `--no-tree-shake-icons` (Device Guard bloquea `font-subset.exe`).

## Dónde mirar
- Estado y plan: `docs/PLAN_PUBLICACION.md` (con la bitácora del jefe); decisiones en `docs/decisions.md`.
- Cumplimiento y tiendas: `docs/COMPLIANCE.md`, `docs/store/`. Diseño: `docs/DISENO_ALMA.md`, `docs/MICROCOPY.md`.
- Agentes propios: `juego-flutter` (código de juegos) y `contenido-fiesta` (contenido).

## Antes de dar algo por hecho
`flutter analyze` limpio y `flutter test` en verde. Cambios de datos, firma o publicación → `habin:revisor`.
