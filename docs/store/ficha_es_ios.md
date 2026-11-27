# Ficha de tienda (es-ES) · Habinson v1.0 · App Store (iOS)

Variante para la build de iOS compilada con `--dart-define=SORBOS=false` (D15): sin modo Sorbos ni textos de beber. La ficha de Google Play sigue en `docs/store/ficha_es.md`.

Cambios respecto a la ficha de Android (`docs/store/CUESTIONARIOS_EDAD.md`, riesgos 2 y 5):
- Fuera la línea de "Consecuencias opcionales +18… agua o reto": en iOS no existe (Apple 2.3, los metadatos describen la app real).
- La Copa de la noche se presenta siempre como trofeo y clasificación, nunca a secas, para que no se lea como bebida.
- Ni "beber", "sorbo", "shot", "apuesta", "casino" ni nombres de bebidas, tampoco en las palabras clave.

## Título

`Habinson: Juegos de fiesta` · 26/30 caracteres.

## Subtítulo (máx. 30)

`Carreras, trivia y retos` · 24/30.

## Descripción

Unos 2.000 caracteres con saltos de línea (límite: 4.000).

```
Habinson reúne ocho juegos para jugar en grupo con un solo móvil. Apuntáis los nombres, elegís juego y a jugar. Sin cuentas, sin anuncios y sin conexión.

La Copa de la noche: el trofeo del grupo
Carrera de caballos y El Infiltrado suman o restan fichas en una clasificación común. Las fichas no tienen valor ni se compran. La clasificación se abre desde la pantalla de inicio y, al final, hay podio con estadísticas por juego. Comparte el resultado con un toque y empieza una noche nueva cuando quieras.

Los juegos
- Carrera de caballos: elige un palo de la baraja, juega de 1 a 5 fichas y sigue la carrera hasta la meta.
- El Infiltrado: todos conocen la palabra menos uno, que solo sabe la categoría. Habla, sospecha y vota. Desde 3 jugadores, pasando el móvil.
- Trivia: cultura general con cuatro opciones por pregunta.
- Geografía: banderas, capitales, siluetas y mapas.
- Abecedario: una palabra por cada letra, de la A a la Z. Anota aciertos y fallos y repasa al final las palabras falladas.
- ¿Quién es más probable?: a la de tres, todos señalan. La carta dice lo que se juega.
- ¿Qué preferirías?: dos opciones, ninguna buena.
- Yo nunca: quien lo haya hecho, lo confiesa.

Tú eliges el tono
Las cartas y las palabras del Infiltrado se adaptan al grupo:
- Suave: para cualquier grupo.
- Picante: ligues, ex y celos, sin nada sexual.
- Modo +18: opcional y desactivado de serie. Solo se activa tras confirmar que todos sois mayores de 18.

Qué hay en juego
Perder fichas significa lo que decidáis en Ajustes:
- Fichas (por defecto): se restan en la clasificación de la Copa.
- Retos: un reto por evento, más fuerte cuanto más se pierde. La Carrera de caballos no se juega en este modo.

Pensada para la mesa
- Un solo móvil para todo el grupo.
- Funciona sin internet.
- Sin registro, sin anuncios y sin compras.
- Habinson no recoge datos: nombres, ajustes y clasificación se guardan en tu móvil.

Habinson está pensada para mayores de 18 años. Juega con responsabilidad.

Algunas preguntas de Trivia proceden de Open Trivia DB (opentdb.com), CC BY-SA 4.0, traducidas y adaptadas al español.
```

## Palabras clave (máx. 100)

```
yo nunca,infiltrado,impostor,amigos,cartas,cultura,geografia,banderas,abecedario,preferirias
```

92/100 caracteres. Igual que en Android: sin espacios tras las comas, sin repetir palabras del título ni del subtítulo, sin marcas de terceros ni términos de alcohol. No añadir "copa" como palabra clave: suelta se lee como bebida.

## Notas de la versión 1.0

```
Primera versión de Habinson:
- Ocho juegos de grupo: Carrera de caballos, El Infiltrado, Trivia, Geografía, Abecedario, ¿Quién es más probable?, ¿Qué preferirías? y Yo nunca.
- Copa de la noche: el trofeo del grupo, con clasificación común, podio final y resultado para compartir.
- Niveles de contenido: Suave y Picante, más un modo opcional +18.
- Qué hay en juego: Fichas o Retos (en Retos no hay Carrera de caballos).
```

## Capturas (iOS)

- La pantalla de la Copa siempre con el trofeo y el podio a la vista.
- Sin cartas del modo +18, sin la palabra "Atrevido" y sin Carrera con apuesta en primer plano (ver "Qué NO mostrar" en `docs/store/CUESTIONARIOS_EDAD.md`).
- Hacerlas con la build `SORBOS=false`: la bienvenida debe decir "Nadie está obligado a nada".
