# Ficha de tienda (es-ES) · Paddock v1.0

Fuentes: `docs/PLAN_PUBLICACION.md` (Fase 6), `docs/CONTENIDO.md`, `docs/decisions.md`, `docs/privacidad.html` y los textos de la app (`lib/`). No describe nada que la app no haga.

## Título

`Paddock: Juegos de fiesta` · 25/30 caracteres (vale para Google Play y App Store).

## Subtítulo / descripción breve

- **Google Play (descripción breve, máx. 80):** `Carreras, trivia y retos en grupo` · 33/80.
- **App Store (subtítulo, máx. 30):** el texto anterior tiene 33 y no cabe. Propuesta: `Carreras, trivia y retos` · 24/30.

## Descripción larga (Google Play y App Store)

Unos 2.300 caracteres (límite: 4.000).

```
Paddock reúne ocho juegos para jugar en grupo con un solo móvil. Apuntáis los nombres, elegís juego y a jugar. Sin cuentas, sin anuncios y sin conexión.

LA COPA DE LA NOCHE
Cada partida suma o resta fichas en un marcador común. La clasificación aparece en la pantalla de inicio y, al final, hay podio con estadísticas por juego. Puedes compartir el resultado con un toque y empezar una noche nueva cuando quieras.

LOS JUEGOS
- Carrera de caballos: apuesta de 1 a 5 fichas por un palo de la baraja y que gane el mejor caballo. ¿Te la juegas con un All-in?
- El Infiltrado: todos conocen la palabra menos uno, que solo sabe la categoría. Habla, sospecha y vota. Desde 3 jugadores, pasando el móvil.
- Trivia: cultura general con cuatro opciones por pregunta.
- Geografía: banderas, capitales, siluetas y mapas.
- Abecedario: una palabra por cada letra, de la A a la Z.
- ¿Quién es más probable?: a la de tres, todos señalan.
- ¿Qué preferirías?: dos opciones, ninguna buena. La minoría paga.
- Yo nunca: confiesa… o paga.

TÚ ELIGES EL TONO
Las cartas y las palabras del Infiltrado tienen tres niveles:
- Suave: para cualquier grupo.
- Picante: ligues, ex y celos, sin nada sexual.
- Atrevido: sugerente, nunca explícito. Está desactivado de serie y solo se activa tras confirmar que todos sois mayores de 18.

CONSECUENCIAS A TU MANERA
Perder fichas significa lo que decidáis en Ajustes:
- Puntos (por defecto): se restan de la Copa.
- Retos: un reto por cada ficha perdida, con un máximo de 3 por ronda.
- Un modo opcional para mayores de edad, desactivado de serie, con tope por ronda y la alternativa de agua o reto siempre a la vista. Nadie está obligado a nada.

PENSADA PARA LA MESA
- Un solo móvil para todo el grupo.
- Funciona sin internet.
- Sin registro, sin anuncios y sin compras.
- No recoge datos: los nombres y los ajustes se quedan en tu móvil.

Paddock está pensada para mayores de 18 años. Juega con responsabilidad.

Algunas preguntas de Trivia proceden de Open Trivia DB (opentdb.com), CC BY-SA 4.0, traducidas y adaptadas al español.
```

## Palabras clave (solo App Store, máx. 100)

```
yo nunca,infiltrado,impostor,amigos,cartas,cultura,geografia,banderas,abecedario,preferirias
```

92/100 caracteres. Sin espacios tras las comas y sin repetir palabras del título ni del subtítulo (Apple ya las indexa). Sin marcas de terceros ni términos de alcohol.

## Notas de la versión 1.0

```
Primera versión de Paddock:
- Ocho juegos de grupo: Carrera de caballos, El Infiltrado, Trivia, Geografía, Abecedario, ¿Quién es más probable?, ¿Qué preferirías? y Yo nunca.
- Copa de la noche: marcador común, podio final y resultado para compartir.
- Niveles Suave, Picante y Atrevido (este último, solo para mayores de 18).
- Consecuencias a elegir: Puntos o Retos.
```

## Pendiente de decidir

- La app llama al marcador **"Copa de la noche"** (`lib/app/cup_screen.dart`). Si se prefiere "Copa Paddock", hay que cambiarlo también en la app para que ficha y producto coincidan.
- Solo Carrera, El Infiltrado y los tres juegos de cartas suman a la Copa (Trivia y Geografía quedan para la v1.1). Por eso la descripción no dice que "todos" los juegos cuentan.
- Capturas (Fase 6): sin nivel Atrevido ni modo Sorbos.
