# Origen de los recursos empaquetados

## Tipografías (SIL OFL 1.1)
Repositorio google/fonts (https://github.com/google/fonts). Licencias en `assets/licenses/`.
- Alfa Slab One: `ofl/alfaslabone` -> `assets/fonts/AlfaSlabOne-Regular.ttf`
- Figtree (variable): `ofl/figtree` -> `assets/fonts/Figtree[wght].ttf`

## Iconos (MIT)
- `assets/fonts/Phosphor-Duotone.ttf` y `assets/fonts/Phosphor-Fill.ttf`: Phosphor Icons (https://phosphoricons.com, https://github.com/phosphor-icons). Añadidos en el commit 972fd04 (2026-11-24).
- **Origen verificado (2026-11-25):** los dos TTF son idénticos byte a byte (mismo SHA-256) a `lib/fonts/Phosphor-Duotone.ttf` y `lib/fonts/Phosphor-Fill.ttf` del paquete `phosphor_flutter` 2.1.0 de pub.dev (https://pub.dev/packages/phosphor_flutter), cuya licencia es MIT, "Copyright (c) 2020-2021 Phosphor Icons", la misma que `assets/licenses/Phosphor-MIT.txt`. El paquete se retiró de `pubspec.yaml` porque no compila con Flutter 3.50 (`IconData` es `final`); solo se conservan las fuentes.

## Sonidos (CC0 1.0, Kenney, https://kenney.nl)
Descargados de kenney.nl el 2026-11-25. Detalle en `assets/audio/LICENSE-Kenney-CC0.txt`.

| Archivo | Pack | Archivo de origen |
|---|---|---|
| `chip.ogg` | Casino Audio (https://kenney.nl/assets/casino-audio) | chips-stack-1 |
| `chip_soft.ogg` | Casino Audio | chip-lay-1 |
| `card.ogg` | Casino Audio | card-slide-1 |
| `correct.ogg` | Music Jingles (https://kenney.nl/assets/music-jingles) | jingles_HIT00 |
| `wrong.ogg` | Music Jingles | jingles_HIT13 |
| `podium.ogg` | Music Jingles | jingles_HIT15 |
| `tap.ogg` | UI Audio (https://kenney.nl/assets/ui-audio) | click1 |

`guillermo_tell.ogg` es aparte: Banda de la Marina de EE. UU., dominio público, vía Wikimedia Commons (ver Créditos en la app).
