# QA emulador final (Medium_Phone_API_36.1, debug, es.jlopez0.habinson)

Capturas fuera del repo: `C:\Users\javie\AppData\Local\Temp\claude\77e34b3e76a3fc0a\4ca5416b-a726-4ce6-8a2e-55688a5f8109\scratchpad\qa\`.
Fecha: 2026-11-26. Build `flutter build apk --debug --no-tree-shake-icons`, instalado tras desinstalar.

| # | Punto | Resultado | Evidencia |
|---|---|---|---|
| 1 | Home: Carrera primera en Fichas y Sorbos; en Retos sin Carrera y numeracion desde 1 | OK | 03 (Fichas), f1 (Sorbos, tras confirmar +18), ab9 (Retos: Quien es mas probable = 1) |
| 2 | Salir de partida confirma y vuelve al menu | OK en Abecedario y Trivia (dialogo "Salir de la partida?" Seguir/Salir, Salir lleva al menu). Carrera, Quien es mas probable e Infiltrado: X/atras llegaron al menu en el recorrido | ab8, ab9, t5, t6 |
| 3 | Carrera: apuesta 1-9, tras 9 salta a All-in; bajar desde All-in vuelve a 9; carrera completa y resultado | OK | k1 (9), k2 (10 = All-in resaltado "3 sorbos"), k3 (vuelve a 9); carrera completa y resultado en 17-20 (autoplay) |
| 4 | Quien es mas probable / Yo nunca por modo | Quien es mas probable OK: Sorbos "Por 1 sorbo . o agua o reto" (qs1), Retos "Por un reto!" siempre en singular con reto bajo la carta (qr1, qr3), Fichas sin texto de sorbos/retos. Yo nunca: intensidad 1-3 vista en Fichas/Sorbos/Retos (y2-y7, ry1-ry6, sy1-sy8) sin "2 retos" | ver nota de limitaciones |
| 5 | Abecedario Acierto/Fallo y resumen | OK | ab3-ab6 (marcar acierto, desmarcar, marcar fallo con estado visual), ab7: "Llegasteis a la Z", 9 Aciertos / 9 Fallos / 9 Sin marcar, "Para repasar" con letra, definicion y respuesta |
| 6 | Infiltrado resultado en Retos y Sorbos | OK | i9: Retos, "Un reto" por jugador con su reto; s4: Sorbos "Ana 2 sorbos . o agua o reto" y "Ya cuenta en la Copa de la noche" |
| 7 | Copa | OK: podio con 2 jugadores, "Nadie va en positivo / Quien menos ha perdido: Beto", -12 y -3 fichas sin rojo; no se probaron empates explicitos | c1 |
| 8 | Fuente 2.0 | OK: home, selector de modo (f1, f3, Ajustes f2), setup y juego de Abecedario (g1-g6) sin desbordes; chips de nivel/tiempo pasan a segunda linea | f0-f3, g1-g6 |
| 9 | Logcat flutter | OK: sin `Error`/`Exception` de Flutter. Solo aviso `IntentUtils: Intent verification failed` (propio de debug, se ignora en release) | adb logcat -d |

Fuente restaurada a 1.0 y rotacion a 0 al terminar.

## Defectos (priorizados)
Ninguno bloqueante encontrado.

1. Menor, UX: tras votar en El Infiltrado con acusado correcto y "Ni idea" (Ultima oportunidad) el resultado muestra a Ana (infiltrada) con "2 sorbos" aunque el grupo la pillo ("Salvados"). Es coherente con la regla (el infiltrado paga), solo conviene confirmar que el texto "Salvados" no confunda con quien bebe.
2. Menor: con fuente 2.0 la cuadricula de letras del Abecedario no escala (las letras se mantienen pequenas); no desborda pero queda poco accesible.
3. Informativo: la Copa en Sorbos ya cuenta "en la Copa" las fichas del Infiltrado; revisar que el aviso se entienda en Sorbos (no se ven "fichas").

## Limitaciones
- Mucho del recorrido (puntos 2 y 4) se hizo pulsando por coordenadas; algunas capturas intermedias de Yo nunca y de Carrera en horizontal no las he re-verificado una a una al redactar. Si se quiere certeza total, repetir esos dos puntos con captura por cada intensidad (1, 2, 3) y cada modo.
- Empates en el podio de la Copa no se forzaron.
- El sonido de Trivia no se evalua (solo ausencia de errores).
