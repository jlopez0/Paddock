# Ficha de tienda (es-ES) · Paddock v1.0

Fuentes: `docs/PLAN_PUBLICACION.md` (Fase 6), `docs/CONTENIDO.md`, `docs/decisions.md`, `docs/privacidad.html` y los textos de la app (`lib/`). No describe nada que la app no haga.

## Título

`Paddock: Juegos de fiesta` · 25/30 caracteres (vale para Google Play y App Store).

## Subtítulo / descripción breve

- **Google Play (descripción breve, máx. 80):** `Ocho juegos de grupo con un solo móvil: trivia, retos, carreras y más` · 69/80.
  - Alternativa corta (la anterior): `Carreras, trivia y retos en grupo` · 33/80.
- **App Store (subtítulo, máx. 30):** `Carreras, trivia y retos` · 24/30.

## Descripción larga (Google Play y App Store)

Unos 2.150 caracteres con saltos de línea (límite: 4.000). Recuento a mano, línea a línea; margen de sobra.

Revisión del 25/11/2026:
- La Copa ya no dice que "cada partida" suma: solo Carrera, El Infiltrado y los juegos de cartas (Trivia y Geografía, en la v1.1).
- Fuera "el mejor caballo" y "¿Te la juegas con un All-in?": evita superlativos y rebaja el tono de apuesta (COMPLIANCE R3). Se aclara que las fichas no tienen valor ni se compran.
- Títulos de sección en minúscula: Google desaconseja las mayúsculas sostenidas en los metadatos.
- Open Trivia DB se cita solo por la atribución que exige su licencia (CC BY-SA 4.0), no como reclamo.

```
Paddock reúne ocho juegos para jugar en grupo con un solo móvil. Apuntáis los nombres, elegís juego y a jugar. Sin cuentas, sin anuncios y sin conexión.

La Copa de la noche
Carrera de caballos, El Infiltrado y los juegos de cartas suman o restan fichas en un marcador común. Las fichas son solo puntos: no tienen valor ni se compran. La clasificación aparece en la pantalla de inicio y, al final, hay podio con estadísticas por juego. Comparte el resultado con un toque y empieza una noche nueva cuando quieras.

Los juegos
- Carrera de caballos: elige un palo de la baraja, juega de 1 a 5 fichas y sigue la carrera hasta la meta.
- El Infiltrado: todos conocen la palabra menos uno, que solo sabe la categoría. Habla, sospecha y vota. Desde 3 jugadores, pasando el móvil.
- Trivia: cultura general con cuatro opciones por pregunta.
- Geografía: banderas, capitales, siluetas y mapas.
- Abecedario: una palabra por cada letra, de la A a la Z.
- ¿Quién es más probable?: a la de tres, todos señalan.
- ¿Qué preferirías?: dos opciones, ninguna buena. La minoría paga.
- Yo nunca: confiesa… o paga.

Tú eliges el tono
Las cartas y las palabras del Infiltrado tienen tres niveles:
- Suave: para cualquier grupo.
- Picante: ligues, ex y celos, sin nada sexual.
- Atrevido: sugerente, nunca explícito. Está desactivado de serie y solo se activa tras confirmar que todos sois mayores de 18.

Consecuencias a tu manera
Perder fichas significa lo que decidáis en Ajustes:
- Puntos (por defecto): se restan de la Copa.
- Retos: un reto por cada ficha perdida, con un máximo de 3 por ronda.
- Un modo opcional para mayores de edad, desactivado de serie, con tope por ronda y la alternativa de agua o reto siempre a la vista. Nadie está obligado a nada.

Pensada para la mesa
- Un solo móvil para todo el grupo.
- Funciona sin internet.
- Sin registro, sin anuncios y sin compras.
- Paddock no recoge datos: nombres, ajustes y marcador se guardan en tu móvil.

Paddock está pensada para mayores de 18 años. Juega con responsabilidad.

Algunas preguntas de Trivia proceden de Open Trivia DB (opentdb.com), CC BY-SA 4.0, traducidas y adaptadas al español.
```

## Palabras clave (solo App Store, máx. 100)

```
yo nunca,infiltrado,impostor,amigos,cartas,cultura,geografia,banderas,abecedario,preferirias
```

92/100 caracteres. Sin espacios tras las comas y sin repetir palabras del título ni del subtítulo (Apple ya las indexa). Sin marcas de terceros ni términos de alcohol.

## Notas de la versión 1.0

Prueba cerrada: ver `docs/store/notas_version_1_0.md`. Mensaje para testers y cuestionario de acceso a producción: `docs/store/mensaje_testers.md`.

Para producción (texto anterior, se mantiene):

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
