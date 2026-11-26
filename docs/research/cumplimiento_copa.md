# Cumplimiento: propuesta de Copa y modos (2026-11-26)

Revisa la alternativa A de `ux_previa.md` (D14) frente a Apple, Google Play, PEGI/IARC y RGPD. **Esto no es asesoría legal**: es una lista de riesgos con el arreglo más sencillo. Leyenda: ✅ cumple · ⚠️ riesgo · ❌ incumple · ❓ no verificable.

## Riesgos, de más a menos grave

| # | Estado | Propuesta | Riesgo real | Mitigación |
|---|---|---|---|---|
| 1 | ⚠️ | **Selector Fichas/Retos/Sorbos en la home** | Es el cambio más delicado. Si "Sorbos" aparece en la primera pantalla, el revisor de Apple verá un juego de beber (4.3(b)) aunque esté desactivado, y la captura `01_home.png` lo mostraría (2.3.8: las capturas deben valer para 4+). | En iOS, compilar sin Sorbos (flag, ya propuesto en COMPLIANCE #3). En Android, poner en la home solo **Fichas / Retos** y dejar Sorbos en Ajustes con su +18, o mostrarlo en la home únicamente tras `adultConfirmed`. Rehacer la captura con el modo Fichas. |
| 2 | ⚠️ | **Copa solo con Carrera e Infiltrado** | En Sorbos, esos son justo los dos juegos que convierten fichas en sorbos. La Copa pasaría a ser casi un espejo de quién ha bebido más, lo que se acerca a la "competición de bebida" que Google no permite presentar de forma favorable. Con Trivia y Geografía (que nunca generan sorbos) dentro, la relación se diluye. | Elegir A o B por UX, pero en los dos casos la Copa debe premiar **solo a quien gana** (podio). Nada de puestos de cola ni de "pérdidas" acumuladas. Desde el punto de vista del cumplimiento, B (con Trivia y Geografía) es algo mejor. |
| 3 | ❌ si se publica así | **"El que más ha pagado"** (`cup_screen.dart:80` y `:457`, también en el texto que se comparte) | En Sorbos se lee "el que más ha bebido". Es un ranking ligado al consumo y además se comparte fuera de la app. | Quitarlo, como se propone. El podio basta. |
| 4 | ✅ mejora | **Yo nunca sin marcar personas, con aviso fijo en Retos y Sorbos** | Reduce el riesgo. Ya no hay recuento por persona y deja de guardarse en el dispositivo qué ha "confesado" cada nombre (contenido Picante o Atrevido). Queda un matiz: el aviso fijo sale en las 20 cartas y no hay tope acumulado. | El aviso debe llevar siempre "o agua o reto" (`ConsequenceBanner` ya lo hace). Opcional: una carta de pausa cada 10 ("Ronda de agua"). |
| 5 | ✅ mejora | **Ocultar la apuesta ("¡Por N fichas!") en el modo Fichas** | Hay menos lenguaje de apuestas a la vista, lo que ayuda con IARC y PEGI (azar simulado) y con la frecuencia que se declara a Apple (COMPLIANCE R3). En Retos y Sorbos sigue apareciendo. | En Sorbos, el titular debería traducir la apuesta ("2 sorbos · o agua o reto") y no anunciar "fichas" que luego se beben. |
| 6 | ✅ | **Sorbos: tope de 3 por ronda y agua o reto siempre visibles** | Ya está en el código (`consequences.dart`, `consequence_banner.dart`). Es la mitigación principal frente a 1.4.3 y Google. | Mantenerlo. Que el test de guardia cubra también la home y Yo nunca. |
| 7 | ✅ | **RGPD** | No cambia nada: no hay red y los nombres se quedan en el dispositivo. Ese uso es doméstico por parte del usuario (RGPD, art. 2.2.c) y el desarrollador no trata datos. El punto 4 reduce además datos sensibles en local. | Nada. La política ya dice "marcador de la noche": si la Copa cambia, no hace falta tocarla. |

## Redacción que hay que evitar (en la app, la ficha, las capturas y el texto compartido)
- **Rankings de consumo.** "El que más ha pagado/bebido", "el más borracho", "quién aguanta más", el último de la Copa en Sorbos.
- **"Pagar" en modo Sorbos.** "Pagan todos", "¿Quién paga?" y "Pagan" significan "beben". En Sorbos, mejor "Le toca a…" o "Reparte", siempre con "o agua o reto". En Fichas y Retos, "pagar" no es un problema.
- **Lenguaje de exceso.** "Fondo", "a morro", "chupito", "ronda doble", "sin límite", "hasta caer", "castigo: bebe". Tampoco "All-in" asociado a sorbos sin el tope ("hasta 3").
- **Beber como meta.** "Juego para emborracharse", "el que pierde bebe" en la ficha. El modo se describe como "consecuencias opcionales".
- **Apuestas reales.** Nada de "€", "dinero", "cuota" ni "casa de apuestas" en la ficha. El tono de hipódromo vale solo como estética.

## Clasificación por edad
- **PEGI/IARC.** Las referencias al alcohol llevan a PEGI 16 o 18. El azar simulado de casino es 18, y las referencias destacadas a apuestas sin simulación, 12. ❓ El resultado final depende del cuestionario de IARC. Contestar con sinceridad: alcohol opcional y apuestas con fichas sin valor.
- **Apple.** 2.3.6 obliga a responder con sinceridad. El sistema 4+/9+/13+/16+/18+ ya está recogido en COMPLIANCE #5. El público objetivo en Play sigue siendo 18+.

## Qué requiere a Javier
Decidir A o B sabiendo lo del punto 2, y aceptar que la home no muestre Sorbos (punto 1). Si Apple rechaza la app por 4.3(b) aun sin Sorbos, conviene que un profesional revise la estrategia de publicación en iOS antes de reenviarla, porque los reenvíos repetidos pueden acabar en expulsión del programa.

## Fuentes (consultadas el 26/11/2026)
- Apple, App Store Review Guidelines, 1.4.3, 2.3.6, 2.3.8 y 4.3(b): https://developer.apple.com/app-store/review/guidelines/ (sin fecha visible).
- Google Play, Inappropriate Content, apartado de tabaco y alcohol (consumo excesivo, en atracón o de competición presentado de forma favorable): https://support.google.com/googleplay/android-developer/answer/9878810 (sin fecha, ©2026).
- PEGI, significado de las etiquetas (alcohol, 16/18; azar simulado, 18; referencias a apuestas, 12): https://pegi.info/what-do-the-labels-mean
- RGPD, Reglamento (UE) 2016/679, art. 2.2.c (actividades exclusivamente personales o domésticas): https://eur-lex.europa.eu/eli/reg/2016/679/oj
- Apple, clasificaciones por edad: https://developer.apple.com/help/app-store-connect/reference/age-ratings (consultada el 24/11/2026, ver COMPLIANCE).
