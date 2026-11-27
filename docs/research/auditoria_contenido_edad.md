# Auditoría de contenido para la clasificación por edad · 2026-11-27

Solo lectura: no se ha tocado ningún asset ni código. Base: `docs/CONTENIDO.md`, `docs/COMPLIANCE.md`, `docs/store/cuestionarios.md` y los JSON de `assets/content/es/`. Objetivo: 18+ en todas las tiendas.

Criterio aplicado (el del encargo): **Atrevido** = sugerente, nunca explícito. **Picante** = pícaro, sin nada sexual. En ningún nivel: alcohol, drogas, insultos fuertes, menores o contexto escolar, humillación real ni riesgo físico en retos.

Tests: `flutter test test/content_test.dart test/extra_content_test.dart` → **65 tests, todos en verde** (la lista negra actual no detecta nada).

Hecho de código que importa para leer esta auditoría (verificado en `lib/`):
- Los mazos arrancan con **Suave + Picante activos** (`prompt_deck_screens.dart:43`). Atrevido pide confirmar +18 (`level_chips.dart`), también en El Infiltrado (`infiltrado_setup_screen.dart:229`).
- En el modo Retos, los retos **Picante salen sin +18** (intensidad 2) y los Atrevido solo con `adultConfirmed` (`retos_filter.dart`).
- Por tanto, **todo lo Picante lo ve cualquier usuario sin confirmar nada**. Por eso lo que en Picante tenga carga sexual es el hallazgo más importante.

## 1. Resumen y recuentos

| Fichero | Suave | Picante | Atrevido | Total | Revisado |
|---|---|---|---|---|---|
| `yo_nunca.json` | 100 | 100 | 80 | 280 | Picante y Atrevido completos |
| `que_preferirias.json` | 65 | 33 | 22 | 120 | Picante y Atrevido completos |
| `quien_es_mas_probable.json` | 64 | 40 | 24 | 128 | Picante y Atrevido completos |
| `retos.json` | 58 | 20 | 12 | 90 | Picante y Atrevido completos |
| `infiltrado.json` | 160 | 8 | 5 | 173 | Picante y Atrevido completos |
| `trivia.json` | — | — | — | 197 (48 de Open Trivia DB) | Búsqueda de términos sensibles |
| `abecedario.json` | — | — | — | 716 entradas | Búsqueda de términos sensibles |
| `geografia/paises.json` + 4 mapas | — | — | — | — | Muestreo: solo nombres, capitales, población y polígonos |

Total revisado a mano: **201 Picante** y **143 Atrevido**.

Resultado:
- **No hay nada explícito.** No aparecen genitales, desnudos gráficos, actos descritos, alcohol, drogas ni insultos. La lista negra funciona.
- **Dudosos: 24 elementos** (tabla 2). De ellos, 9 son de **contexto familiar o de "primera vez"**, que pueden remitir a menores, y 6 son Atrevido que rozan lo explícito.
- **Cambios de nivel: 4 Picante deberían ser Atrevido** (o reescribirse) y unos 14 Atrevido son en realidad Picante (sección 3).
- **Trivia, Abecedario y Geografía:** sin problemas de edad. Hay referencias históricas a guerras o asesinatos, y definiciones de "póker" y "quiniela", todo en tono educativo (sección 2.3).

## 2. Elementos dudosos

### 2.1 Mazos y Retos

| id | Nivel | Texto | Problema | Propuesta |
|---|---|---|---|---|
| yn108 | Atrevido | he pillado a mis padres en un momento íntimo | Sexo de los padres visto por el hijo: el contexto natural es que el jugador era menor y vivía en casa | **Quitar** |
| yn161 | Atrevido | he tenido un momento íntimo con mis padres en la habitación de al lado | Implica vivir con los padres; se lee como adolescente | **Suavizar**: "he tenido un momento íntimo con visita en la habitación de al lado" |
| yn318 | Atrevido | he tenido un momento íntimo en la cama de mis padres | Igual que el anterior; además repite yn072 ("una cama que no era ni mía ni suya") | **Quitar** (yn072 ya cubre la idea) |
| qp037 | Atrevido | Que tus padres te pillen en un momento íntimo / Pillar tú a tus padres | Igual que yn108 | **Suavizar**: "Que tu compañero de piso te pille en un momento íntimo / Pillar tú a tu compañero de piso" |
| yn116 | Atrevido | he mentido sobre cómo fue mi primera vez | "Primera vez" equivale a "virginidad" (en la lista negra) y suele remitir a la adolescencia | **Quitar** (yn104, "he exagerado mi experiencia en la cama", cubre la idea) o aceptarlo como riesgo |
| yn156 | Atrevido | me he arrepentido de con quién fue mi primera vez | Igual que yn116 | **Suavizar**: "me he arrepentido de con quién acabé la noche al día siguiente" |
| qmp_083 | Picante | mienta sobre su edad para ligar | Ambiguo: puede leerse como un menor que se hace pasar por mayor | **Suavizar**: "se quite años en su perfil de ligar" |
| yn266 | Atrevido | he tenido un juguete erótico en casa | Objeto sexual nombrado directamente: lo más cercano a lo explícito del mazo | **Quitar** (yn233, "tienda erótica", ya cubre el tema) o suavizar: "he escondido algo en el cajón de la mesilla antes de una visita" |
| yn114 | Atrevido | he consultado el kamasutra para inspirarme | Remite a un manual de posturas sexuales | **Suavizar**: "he buscado ideas en internet para sorprender a mi pareja" |
| yn121 | Atrevido | he fingido en la cama | Alude a fingir un orgasmo, un acto sexual concreto aunque implícito | Límite. **Mantener** o suavizar: "he fingido que algo me encantaba solo por no cortar el rollo" |
| yn134 | Atrevido | le he roto la ropa a alguien con las prisas por quitársela | Describe cómo se desviste a alguien en plena escena: es el más descriptivo | **Suavizar**: "he perdido un botón por las prisas en un momento apasionado" |
| yn047 | Atrevido | he hecho un striptease para alguien | Desnudo implícito (el criterio prohíbe desnudos) | **Suavizar**: "he hecho un baile sensual para alguien" (ojo: qmp_109 dice casi lo mismo) |
| yn122 | Atrevido | he salido de casa sin ropa interior | Roza la desnudez, pero no la describe | Límite. **Mantener** |
| yn278 | Picante | he ligado con tres o más personas a la vez | "A la vez" puede leerse como un trío ("trío" está en la lista negra). En Picante se ve sin +18 | **Suavizar**: "he estado tonteando con tres personas la misma semana" |
| yn043 | Picante | he tenido un rollo de una noche | Implica sexo. Picante se ve sin +18, y qmp_124 ("rollo de una noche en vacaciones") está en Atrevido | **Mover a Atrevido** |
| yn066 | Picante | he dudado de mi orientación | No es sexual, pero presenta la orientación como una "confesión picante" y puede forzar a alguien a salir del armario delante del grupo | **Quitar** (recomendado) o pasar a Suave con otra formulación |
| yn275 | Picante | he tenido algo con alguien de mi mismo género | Mismo riesgo que yn066 (una revisión de Apple 1.1.1 podría verlo como estigmatizante) | **Quitar** o aceptar el riesgo de forma consciente |
| rt_060 | Picante | Lee en voz alta el último mensaje que has enviado (puedes saltarte uno si es privado) | Privacidad: si el segundo mensaje también es privado, no hay salida. Puede humillar | **Suavizar**: "Lee en voz alta uno de tus últimos cinco mensajes, el que tú elijas" |
| rt_083 | Atrevido | Lee con voz sensual lo último que tengas apuntado en el móvil | El mismo riesgo de privacidad | **Suavizar**: "Lee con voz sensual una nota o lista del móvil que tú elijas" |
| rt_079 | Atrevido | Susurra al oído de la persona de tu izquierda algo que te parezca atractivo de ella | Acercamiento físico sin pedir permiso (rt_087 y rt_089 sí lo piden) | **Suavizar**: añadir ", si le parece bien; si no, díselo en voz alta" |
| rt_080 | Atrevido | Dedica tu mirada más seductora durante cinco segundos a quien elija el grupo | Quien recibe la mirada no elige. Es leve | **Suavizar**: "…a quien elija el grupo, si le parece bien" |
| rt_062 | Picante | Suelta tu mejor frase para ligar a la persona de tu derecha | Puede incomodar si esa persona está con su pareja delante. Es leve | **Mantener** o: "…a quien tú elijas del grupo" |
| yn187 / yn419 / yn290 / yn292 / yn142 / yn044 / qp041 / qmp_122 / qmp_123 / rt_082 | Atrevido | Encuentros en playa, ascensor, probador, coche o "sitio arriesgado" | Insinúan sexo en lugares públicos. Son confesiones, no retos que se pidan hacer, así que no entran en "retos ilegales" | **Mantener**. Solo en yn187, cambiar "arriesgado" por "poco habitual" para que no se lea como riesgo físico |
| qmp_095 | Picante | ponga los cuernos | Señalar en voz alta a una persona presente como posible infiel puede crear un conflicto real | **Mantener** (es el formato del juego); a vigilar |

### 2.2 Revisados y sin problema (Atrevido)

Encajan en "sugerente, no explícito": yn045 (esposas), yn097 (nata o chocolate), yn128 (hielo), yn191, yn192, yn268, yn083, yn418, yn328, yn415, qmp_119 (fotos, audios y videollamadas subidos de tono entre adultos), yn320 (fetiche), los qp036–qp045 y qp109–qp120 no citados arriba, y los qmp_105–qmp_128 no citados arriba. `docs/COMPLIANCE.md` (#7) ya lo había valorado así.

### 2.3 Trivia, Abecedario y Geografía

| id | Texto | Valoración |
|---|---|---|
| Trivia (varias), p. ej. "Guerra Civil española", "bombas atómicas sobre Hiroshima y Nagasaki", "Primera Guerra Mundial" | Historia | Referencia histórica educativa. No cuenta como "violencia" en IARC ni en Apple. Mantener |
| ot-his06 | "¿Qué día de enero de 1933 fue nombrado Hitler canciller de Alemania?" | Dato histórico neutro. Mantener. Ojo: en Alemania, IARC/USK no pone pegas a una mención textual sin símbolos (❓ no verificado para USK) |
| ot-his07 | "¿Quién asesinó al presidente estadounidense James A. Garfield?" | Histórico. Mantener |
| ot-oci03 | "¿Cómo se llama el asesino de la primera película de «Hellboy»?" | Cine. Mantener |
| Abecedario: kamikaze, búnker, pólvora, nigromancia, carroña, zombi | Definiciones de diccionario | Sin problema |
| Abecedario: póker ("Juego de cartas con apuestas"), quiniela ("Apuesta de resultados de partidos de fútbol") | Mención de juegos de azar | Es solo una definición, no azar simulado. No cambia la declaración (el azar simulado ya se declara por la Carrera) |
| Abecedario r-u1 "uva" | "Fruto pequeño y redondo de la vid" | Sin mención del vino. Correcto |
| Geografía | Nombres de países, capitales y provincias | Sin contenido sensible. No se ha revisado si hay nombres de territorios en disputa (❓ no verificado: puede ser un tema político en algunos países, pero no afecta a la edad) |

Búsqueda extra de alcohol y drogas fuera de la lista negra (copa, cóctel, licor, cava, sidra, bar, pastilla, hierba, tabaco, cigarro, vaper, casino…): solo hay usos inocuos ("copa" de un árbol, "Copa Davis", "mala hierba"). Única ambigüedad: **"Copa de la noche"** (nombre del marcador, `ayuda.json`), porque en España "copa" también significa bebida. No hace falta declararlo, pero conviene que las capturas y la ficha lo presenten como trofeo.

### 2.4 Propuesta para la lista negra (no aplicada: es una auditoría de solo lectura)

- Explícitas (cartas, retos e infiltrado): `kamasutra`, `juguete erótico` (frase; con palabras sueltas, `erótico`/`erótica` ya están vetados en Suave), `striptease` (hoy solo vetado en Suave).
- Menores, en Picante y Atrevido: valorar vetar la frase "primera vez" y la combinación de "padres" con "íntimo". El test trabaja con palabras sueltas, así que haría falta una comprobación de frases.

## 3. Cambios de nivel

### 3.1 Picante que en realidad es Atrevido (lo ve cualquiera sin +18)

| id | Texto | Propuesta |
|---|---|---|
| yn043 | he tenido un rollo de una noche | Mover a Atrevido (es coherente con qmp_124) |
| yn278 | he ligado con tres o más personas a la vez | Reescribir (ver 2.1) o mover a Atrevido |
| yn203 | me han pillado un chupetón en el trabajo | Límite. Mantener: es un beso, no sexo |
| yn226 | he soñado que me liaba con alguien… | Mantener ("liarse" = besarse) |

### 3.2 Atrevido que en realidad es Picante (sin carga sexual)

| id | Texto | Propuesta |
|---|---|---|
| qp039 | Un rollo con tu crush imposible / Una relación estable… | Picante |
| qp043 | Besar a alguien de este grupo / Confesar a quién de aquí besarías | Picante |
| qp111 | Un masaje de una hora / Un desayuno en la cama | Picante |
| qp114 | Una noche romántica en un hotel de lujo / Una escapada improvisada a una cabaña | Picante |
| qp115 | Una pareja muy atrevida / Una pareja muy romántica | Picante |
| qp118 | Un beso de película bajo la lluvia / … en lo alto de una noria | Picante |
| qmp_111 | tenga una carpeta oculta en el móvil | Picante |
| qmp_120 | ligue con dos personas en la misma noche | Picante (yn067, "me he liado con dos personas… la misma noche", ya es Picante) |
| qmp_126 | tenga planes con alguien después de esta fiesta | Picante |
| qmp_128 | dé el primer paso sin pensárselo dos veces | Picante |
| rt_081 | Describe tu cita perfecta de principio a fin… | Picante |
| rt_086 | Di qué persona del grupo crees que besa mejor | Picante |
| rt_089 | Invita a alguien… a un baile lento… si no quiere, baila con un cojín | Picante |
| inf_169, inf_171, inf_173 | Jacuzzi, Masaje, Velas aromáticas | Picante o Suave: son palabras neutras. Si se mueven, Atrevido se queda con 2 palabras (Lencería, Motel) y habría que añadir otras sugerentes y no explícitas o fusionar la categoría con "Amor y ligue" |

Nota: si se mueve todo lo de 3.2, cambian las cifras de `docs/CONTENIDO.md` y los mínimos del test (Atrevido de ¿Qué preferirías? baja de 22 a 16, y el de ¿Quién es más probable? de 24 a 20). Ningún mínimo del test depende de Atrevido (❓ verificado solo para los mínimos que cita `CONTENIDO.md`).

## 4. Qué declarar en IARC (Google Play) y Apple

La propuesta de `docs/store/cuestionarios.md` se sostiene. Matices de esta auditoría:

| Tema | IARC (Google Play) | Apple (App Store Connect) | Motivo |
|---|---|---|---|
| Referencias sexuales | **Sí: insinuaciones o referencias sexuales, sin desnudos ni actos explícitos** | Contenido sexual o desnudez: **Poco frecuente**. Explícito: **Ninguno** | 143 elementos Atrevido sugerentes, tras +18. Ninguno es explícito |
| Temas maduros o sugerentes | (dentro de sexualidad y humor) | **Poco frecuente**. ❓ Valorar **Frecuente**: Picante (201 elementos: ligues, cuernos, ex) está **activo por defecto** y se ve sin +18 | La frecuencia la decide el volumen visible por defecto, no solo Atrevido |
| Humor grosero o sugerente | **Sí**, si el formulario lo pregunta aparte | Palabrotas o humor grosero: **Poco frecuente** | Humor pícaro sin insultos (la lista negra lo garantiza) |
| Lenguaje soez | No | (incluido arriba) | No hay insultos ni palabrotas |
| Alcohol | **Sí** (referencia y uso, por el modo Sorbos de Android). Los JSON de contenido **no** contienen alcohol | Alcohol, tabaco o drogas: **Poco frecuente** en Android/universal. En la build de iOS con `SORBOS=false` ❓ se podría responder Ninguno, pero los literales siguen en el binario (`COMPLIANCE.md`, D15). Decisión de Javier | Lo que hace declarar alcohol es la mecánica, no el contenido |
| Drogas y tabaco | No | Ninguno | No aparecen (búsqueda hecha en todos los JSON) |
| Violencia | No | Ninguno | Solo menciones históricas en Trivia, en tono educativo |
| Azar simulado | Sí (Carrera, fichas sin valor) | Poco frecuente o Frecuente (decisión pendiente, `COMPLIANCE.md` R3) | No depende del contenido auditado |
| Menores | — | — | **No hay contenido sexual con menores.** Sí hay 7 elementos de contexto familiar o "primera vez" (tabla 2.1) que conviene quitar o suavizar **antes** de enviar el cuestionario: es lo que más puede preocupar a un revisor humano |

Conclusión: con el contenido actual, **18+ en Apple y PEGI 18 en IARC son coherentes y defendibles** (sexualidad sugerente + mecánica de alcohol + azar simulado). Ningún elemento obliga a declarar contenido explícito. Antes de enviar, recomiendo:
1. Quitar o suavizar los 7 de contexto familiar o "primera vez" (yn108, yn161, yn318, qp037, yn116, yn156, qmp_083).
2. Sacar de Picante yn043 y yn278, porque Picante se ve sin +18.
3. Suavizar los 4 Atrevido más cercanos a lo explícito (yn266, yn114, yn134, yn047).
4. Decidir sobre yn066 y yn275 (orientación).
5. Ampliar la lista negra según 2.4.

Lo marcado con ❓ no se ha podido verificar: el texto real de los formularios, la postura de USK y la respuesta de alcohol para la build de iOS. Esto no es asesoría legal.
