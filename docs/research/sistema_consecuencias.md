# Sistema de consecuencias: propuesta para decidir (2026-11-26)

Estado: **decidido: intensidad 1–3 solo en Yo nunca/Quién es más probable; Carrera sigue 1–9+All-in; Retos = 1 carta por nivel; quizzes sin consecuencia** (D20, `docs/decisions.md`, 2026-11-26). Lo que sigue es la propuesta original; donde choca con esta línea manda D20 (p. ej. la apuesta 1–3 de la Carrera y las consecuencias en quizzes no se aplican).

## 1. El problema, tal como se ve hoy

1. **La ficha es una moneda inventada que no encaja en la mayoría de juegos.** Solo la Carrera es una apuesta de verdad. En Yo nunca, ¿Quién es más probable?, Infiltrado o los quizzes no hay nada que apostar: la ficha es un número que se traduce a otra cosa.
2. **Dos capas confunden.** El juego habla en fichas, el modo traduce a retos/sorbos con tope 3. Quien juega no sabe qué le toca ni por qué.
3. **"2 o 3 retos" no tiene sentido.** Un reto es un acto único. Más de uno obliga a acumular, y nadie sabe quién elige ni cuándo se cumplen.
4. **El núcleo de la previa es beber** (sorbos). Hoy el modo que más se usará es el que peor encaja con el diseño en "fichas".

## 2. Principios

- **La consecuencia pertenece al momento del juego, no a una moneda.** Cada juego dice quién incumple y cuánto de grave es.
- **La app decide, no el grupo.** Quien pierde no discute: la app muestra el reto o los sorbos. Se acaba el "¿quién lo decide?".
- **Un solo evento, una sola consecuencia visible.** Nada de sumar ni de acumular entre rondas.
- **El vocabulario del modo es el del juego.** En Sorbos se habla de sorbos; en Retos, de retos; en Fichas, de puntos. Sin capa intermedia.
- **Cumplimiento intacto**: Sorbos solo con +18, tope 3 por evento, "o agua o reto" siempre a la vista, sin Sorbos en iOS.

## 3. Propuesta: nivel de intensidad por evento (1–3), no cantidad de fichas

Cada evento con perdedor tiene una **intensidad de 1 a 3** (la decide el juego: la apuesta en Carrera, una carta suave/picante/fuerte en los mazos, etc.). El modo la traduce:

| Intensidad | Sorbos (+18) | Retos | Fichas (sin consecuencia real) |
|---|---|---|---|
| 1 | 1 sorbo | reto suave | 1 punto |
| 2 | 2 sorbos | reto medio | 2 puntos |
| 3 | 3 sorbos (tope) | reto picante | 3 puntos |

Clave de **Retos**: nunca varios retos. La intensidad elige **de qué nivel sale el reto** (el mazo `retos.json` ya tiene suave/picante/atrevido) y la app saca **una carta de reto** que lo cumple quien incumple. Resuelve "¿quién lo decide?": la app.

## 4. Qué hace cada juego

| Juego | Evento con consecuencia | Quién | Intensidad |
|---|---|---|---|
| Carrera de caballos | Apuesta fallada (y repartir si aciertas) | Quien apostó | La apuesta (1–3); All-in = 3 + reparte |
| ¿Quién es más probable? | Carta en la que le señalan | El más señalado | La de la carta |
| Yo nunca | "Yo nunca..." confesado | Quien lo hizo | 1 fija |
| El Infiltrado | Fin de ronda | Los que pierden el bando | 1–2 según el resultado |
| ¿Qué preferirías? | Sin consecuencia (solo debate) | — | — |
| Abecedario / Trivia / Geografía | Fallo o tiempo agotado | Quien falla | 1 |

La **Copa** sigue mínima: solo Carrera e Infiltrado suman, podio de 3. Sin cambios respecto a D14 (puntos simbólicos).

## 5. Qué cambia respecto a hoy

- Apuesta de Carrera: de 1–9 + All-in a **1–3 + All-in** (el 4–9 solo se justificaba como fichas; en sorbos ya se recortaba a 3). Más simple y coherente en los tres modos.
- Desaparece el mensaje de "fichas → sorbos con tope": el tope es la propia escala 1–3.
- Retos pasa de "N retos" a "1 reto del nivel que toca".
- Quizzes y Abecedario ganan consecuencia opcional (hoy no tienen).
- En Fichas, el resto de juegos no muestran nada salvo donde ya suman (Carrera, Infiltrado).

## 6. Riesgos

- Reducir la apuesta máxima cambia partidas guardadas (migración: recortar a 3).
- Sorbos en quizzes puede empujar a beber por fallar: mantener +18, tope 1 y la alternativa visible.
- Hay que reescribir `ConsequenceBanner`, `stakeHeadline`, `resolveLoss` y tests de tres juegos.

## 7. Decisiones que necesito de Javier

1. ¿Intensidad 1–3 como escala común (y apuesta de Carrera 1–3 + All-in)?
2. ¿Retos = una carta de reto de nivel según intensidad?
3. ¿Quizzes/Abecedario con consecuencia (1 sorbo o 1 reto al fallar)?
