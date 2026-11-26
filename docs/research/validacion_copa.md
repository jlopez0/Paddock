# Validación: qué suma a la Copa (A, B o C) · 2026-11-26

Estado: **opinión del validador, pendiente de Javier**. Fuentes: `ux_previa.md` (D14), `previa_puntos.md`, `DISENO_COPA.md` (D13). No hay datos de grupos reales: todo lo de abajo es inferencia.

## Lo que no se decide aquí (hágase con A, B o C)
Los cambios 1, 2, 4 y 5 de `ux_previa.md` (Yo nunca deja de marcar personas, "¡Por N fichas!" oculto en Fichas, fuera "el que más ha pagado" y "Puntos" pasa a "Fichas") valen para cualquier opción y son los que más fricción quitan. A frente a B solo decide **Trivia y Geografía**. No conviene darle más peso del que tiene.

## Opciones (1-5; en riesgo y coste, 5 = bajo)
| Opción | Comprensión | Fluidez | Diversión | Riesgo tienda | Coste | Total |
|---|---|---|---|---|---|---|
| A. Copa de apuestas: suman Carrera e Infiltrado | 4 | 4 | 3 | 4 | 4 | **19** |
| B. Suman los 4, con "¿Quién la ha clavado?" | 3 | 3 | 3 | 4 | 3 | **16** |
| C. A sin escaparate: mismas fuentes que A, sin insignias ni línea "Cuentan", sin top 3 en la home; "Ver Copa" solo al cerrar Carrera o Infiltrado y en el menú | 5 | 5 | 3 | 5 | 4 | **22** |

- **Contra A:** si el grupo no juega a la Carrera, la Copa se queda en los negativos del Infiltrado (solo resta), y eso apenas es una clasificación. Además deshace la 3.11 del 25/11.
- **Contra B:** añade una pregunta de gestión en cada partida de preguntas, en el peor sitio (todos gritan la respuesta). Como da 3 fichas como máximo frente a los ±10/20 del All-in, no cambia el podio. Mucho trabajo para un efecto pequeño.
- **Contra C:** si nadie ve la Copa, puede acabar siendo código muerto. Con lo que sabemos, eso no es un fallo: nada indica que haya demanda (ver abajo).

**Recomendación: C (A recortada).** Mantiene las fuentes de A y quita el escaparate. Encaja con la regla 3 de `previa_puntos.md`: el marcador se ve solo si alguien lo abre. Además es lo más barato y lo que menos retrasa publicar. Antes de programar, hay que validarlo con la prueba de abajo.

## Afirmaciones poco apoyadas
- `previa_puntos`: dice que "ningún competidor vende marcador", pero se basa en 3 fichas leídas y deja 5 sin verificar. **Google Play no está mirado**, y es el canal principal en Android ES. Que no haya reseñas que pidan marcador no demuestra nada: la muestra es mínima. Fiesta, con 2 valoraciones, no prueba nada ni a favor ni en contra. Lo de "Copa mínima = diferencia posible" no tiene ningún dato detrás.
- `previa_puntos`: el riesgo de Google por "competición de bebida" está sin confirmar. Lo de que la ruleta y Yo nunca son ágiles sale de un blog, no de una fuente primaria.
- `ux_previa`: "en una previa nadie ha jugado solo", "marcar en Yo nunca es el mayor freno" y "nadie elige juego por el marcador" son hipótesis que nadie ha observado. Los "~1,5 días" de A y de B, y los "7-8 conceptos" de B, son estimaciones. Lo de "<15 s en 4 toques" es un objetivo, no algo medido.
- `DISENO_COPA`: se contradice. La regla es "solo suma lo que decide la app", pero Geografía en modo Mental acepta "Acerté" de palabra. Eso debilita el argumento a favor de B.

## Paso más pequeño (≤1 semana, 0 código)
1. Jugar con **la versión actual**, que ya se comporta como B, en 2-3 previas reales de 4-8 personas. Un observador apunta en el móvil, sin intervenir.
2. Medir 4 cosas: segundos hasta la 1ª carta; si en Trivia o Geografía rellenan "¿Quién ha jugado?" o se lo saltan; cuántas veces alguien pregunta "¿esto cuenta?"; y si alguien abre la Copa **sin que se lo pidan**.
3. Regla de decisión:
   - Si nadie abre la Copa en 2 de los 3 grupos: **C**.
   - Si la abren, pero saltan o se quejan de "¿Quién ha jugado?": **A**.
   - Si la rellenan sin queja y comentan la clasificación: **B**.

Mientras tanto se pueden hacer los cambios comunes (1, 2, 4 y 5), porque no dependen del resultado. El punto 2.4 sigue pendiente de `habin:cumplimiento`.
