# Origen de los recursos empaquetados

Registro de trazabilidad (COMPLIANCE.md #10, R1, R2). Lo marcado como **NO VERIFICADO** no se pudo comprobar y no debe darse por bueno sin revisarlo.
Los textos completos de las licencias MIT y OFL van en `assets/licenses/` y se muestran en la pantalla de Licencias de la app.

## Tipografías (SIL OFL 1.1)
Origen declarado: repositorio google/fonts (https://github.com/google/fonts). Licencias en `assets/licenses/`.
- Alfa Slab One, `ofl/alfaslabone` -> `assets/fonts/AlfaSlabOne-Regular.ttf`. Copyright de los autores del proyecto Alfa Slab One. Nombre reservado "Alfa Slab" (solo afecta a versiones modificadas; el TTF es el original).
- Figtree (variable), `ofl/figtree` -> `assets/fonts/Figtree[wght].ttf`. Copyright de los autores del proyecto Figtree.
- Fecha de incorporación: 2026-11-24 (commit 972fd04).
- **NO VERIFICADO:** la versión exacta y el commit de google/fonts de los que se copiaron los TTF no constan en el repositorio. Si hace falta, compararlos con la versión actual de google/fonts por hash.

## Iconos Phosphor (MIT)
- Archivos: `assets/fonts/Phosphor-Duotone.ttf` y `assets/fonts/Phosphor-Fill.ttf`. Incorporados el 2026-11-24 (commit 972fd04).
- Licencia: MIT, "Copyright (c) 2020-2021 Phosphor Icons" (`assets/licenses/Phosphor-MIT.txt`).
- **Origen verificado (2026-11-25, por hash SHA-256):** los dos TTF son idénticos byte a byte a `lib/fonts/Phosphor-Duotone.ttf` y `lib/fonts/Phosphor-Fill.ttf` del paquete `phosphor_flutter` 2.1.0 de pub.dev (https://pub.dev/packages/phosphor_flutter), comprobado contra la copia de la caché local de pub.
  - Duotone: `80e6f0d6fa8ce96a9933f48aaabddc592c5d2b52caf8f010a7e54a17c74084bf`
  - Fill: `a53f5d2630cab5e3b7536ecb9d69d71519a2190298c22b1f8d770dd37bc2940a`
- El paquete se retiró de `pubspec.yaml` porque no compila con Flutter 3.50 (`IconData` es `final`); solo se conservan las dos fuentes. Los códigos de glifo están en `lib/app/app_icons.dart`.
- **NO VERIFICADO:** la versión del repositorio upstream de Phosphor (phosphor-icons/web o /core, https://github.com/phosphor-icons) de la que `phosphor_flutter` 2.1.0 generó esas fuentes. El paquete de pub.dev es el único origen comprobado; no se inventa una versión del upstream.

## Sonidos (CC0 1.0, Kenney, https://kenney.nl)
Descargados de kenney.nl el 2026-11-25. Detalle en `assets/audio/LICENSE-Kenney-CC0.txt`. La atribución no es obligatoria (se da por cortesía).

| Archivo | Pack | Archivo de origen |
|---|---|---|
| `chip.ogg` | Casino Audio 1.1 (https://kenney.nl/assets/casino-audio) | chips-stack-1 |
| `chip_soft.ogg` | Casino Audio 1.1 | chip-lay-1 |
| `card.ogg` | Casino Audio 1.1 | card-slide-1 |
| `correct.ogg` | Music Jingles (https://kenney.nl/assets/music-jingles) | jingles_HIT00 |
| `wrong.ogg` | Music Jingles | jingles_HIT13 |
| `podium.ogg` | Music Jingles | jingles_HIT15 |
| `tap.ogg` | UI Audio (https://kenney.nl/assets/ui-audio) | click1 |

`guillermo_tell.ogg` es aparte: Obertura de Guillermo Tell (Rossini), grabación de la Banda de la Marina de EE. UU. ("Grand Scenes", 2000), obra del gobierno de EE. UU. en dominio público, vía Wikimedia Commons. **NO VERIFICADO:** la URL exacta del archivo en Commons no consta en el repositorio.

## Confeti (MIT)
Paquete pub.dev `confetti` 0.8.0 (https://pub.dev/packages/confetti), "Copyright (c) 2018 Felix Angelov", dependencia directa (`pubspec.lock`). Aviso en `assets/licenses/confetti-MIT.txt`.

## Baraja española (CC BY-SA 3.0)
Las cartas de `assets/cards/` son recortes y reescalados de la baraja de Wikimedia Commons:
- "Baraja española completa.png", de Basquetteur (2014-05-18), obra derivada del trabajo de Germarquezm: https://commons.wikimedia.org/wiki/File:Baraja_espa%C3%B1ola_completa.png
- "Baraja española.svg", de Germarquezm: https://commons.wikimedia.org/wiki/File:Baraja_espa%C3%B1ola.svg
- Autoría: https://commons.wikimedia.org/wiki/User:Basquetteur y https://commons.wikimedia.org/wiki/User:Germarquezm
- Licencia de ambos archivos: CC BY-SA 3.0 (https://creativecommons.org/licenses/by-sa/3.0/), según la página de cada archivo (comprobado el 2026-11-25).
- Cambios: recortadas en cartas individuales y reescaladas. Las cartas derivadas se comparten con la misma licencia (compartir igual).
- Las páginas de Commons indican además que reutilizan gráficos heráldicos y un caballo de GnuBond (Aisleriot); no se han revisado esas licencias una por una.
- **Pendiente (R2):** publicar las cartas recortadas en `docs/` con su licencia.

## Trivia (CC BY-SA 4.0)
Las preguntas con id `ot-` proceden de Open Trivia DB (https://opentdb.com), licencia CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/), traducidas y adaptadas. El resto son originales. **Pendiente (R2):** publicar las `ot-` en `docs/` con su licencia.

## Geografía
Natural Earth (dominio público, https://www.naturalearthdata.com) para siluetas y mapas; banderas de flagcdn.com / Flagpedia (https://flagpedia.net, dominio público según su web). **NO VERIFICADO:** fecha y versión de la descarga.

## Dibujados para la app
Jockey, trofeo, fichas, boleto y medallas: código propio (`lib/app/mascot.dart`, `lib/app/app_icons.dart`). Sin recursos de terceros.
