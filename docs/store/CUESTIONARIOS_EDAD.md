# Cuestionarios de edad · Habinson v1.0 (respuestas pregunta por pregunta)

Fecha: 27/11/2026. Responsable: `habin:cumplimiento`. **No es asesoría legal.** Es una propuesta de respuestas sinceras para que Javier las compare con el formulario real antes de enviar.

Sustituye a las tablas de `docs/store/cuestionarios.md` en lo que choquen. Ese archivo usaba nombres de preguntas de Apple anteriores a 2025 y suponía que iOS llevaba Sorbos.

Leyenda: ✅ confirmado en la fuente oficial · ⚠️ riesgo · ❌ incumple · ❓ no verificable desde aquí (hay que confirmarlo en pantalla).

## Punto de partida (decisión de Javier)

| Build | Sorbos | Atrevido | Objetivo |
|---|---|---|---|
| Android (Google Play) | Sí: opcional, apagado de serie, +18 confirmado, tope 3 por ronda, alternativa agua o reto siempre visible | Sí: sugerente, no explícito, apagado de serie, +18 | 18+ / PEGI 18 |
| iOS (`--dart-define=SORBOS=false`) | No: el selector, el diálogo y los textos de beber no se ven (D15). Los literales siguen en el binario, pero no se puede llegar a ellos | Sí, igual que en Android | 18+ |

Contenido real que se declara (lo he comprobado en `assets/content/es/`):
- **Atrevido** (unas 143 cartas entre Yo nunca, ¿Qué preferirías?, ¿Quién es más probable?, Retos e Infiltrado): actividad sexual **insinuada** ("acabar en la cama", "momento íntimo", "striptease", "esposas"). No hay nada explícito ni desnudos. Dentro del nivel, casi todas las cartas son de este tipo.
- **Picante** (activo de serie junto a Suave): ligues, ex, cuernos y celos.
- **Humor grosero leve**: por ejemplo yn132, gases. Sin insultos (lista negra del test).
- **Azar simulado**: en la Carrera de caballos se apuestan fichas sin valor, de 1 a 9 más el All-in, y es el primer juego de la home.
- **Concursos**: Trivia, Geografía y el podio de la Copa.
- **Alcohol**: solo en el modo Sorbos de Android. El contenido JSON no menciona alcohol (lo vigila la lista negra).
- Sin red, cuentas, chat, anuncios, compras ni ubicación. Los enlaces se abren en el navegador del sistema y son siempre los mismos (privacidad, soporte y licencias).

---

## (a) Google Play · Cuestionario IARC + Público objetivo

### Lo que está confirmado y lo que no
- ✅ El cuestionario se rellena en Play Console > Contenido de la app. Se elige una categoría, se responden todas las preguntas y en el resumen aparecen las clasificaciones calculadas, PEGI incluida en Europa (Google, answer/9859655, ©2026, consultada el 27/11/2026).
- ✅ Hay que contestar con exactitud. Si el contenido cambia, se repite el cuestionario. Si se tergiversa el contenido, la app puede retirarse o suspenderse (Google, answer/9898843 y answer/188189, ©2026, consultadas el 27/11/2026).
- ❓ **IARC no publica el texto exacto de las preguntas.** Ninguna página oficial de Google ni de IARC que haya podido abrir las enumera (la de IARC daba 404). Los bloques de abajo siguen la estructura habitual del formulario y **hay que cotejarlos con la pantalla**. Donde la pregunta no coincida, aplicar la regla: *declarar el hecho tal cual, sin inflarlo ni quedarse corto*.

### Respuestas

| # | Bloque / pregunta (nombre ❓) | Respuesta | Por qué |
|---|---|---|---|
| 0 | Correo de contacto IARC | Correo real del desarrollador (no `CORREO_DE_CONTACTO`) | IARC envía el certificado a ese correo |
| 1 | Categoría | **Juego** ❓ (si aparece "Juego de cartas o de fiesta" o similar, esa) | Es un recopilatorio de juegos |
| 2 | Violencia (de cualquier tipo, sangre, armas) | **No** a todo | Ningún juego tiene violencia |
| 3 | Miedo / terror | **No** | — |
| 4 | Sexualidad: ¿referencias, insinuaciones o contenido sexual? | **Sí, insinuaciones o referencias sexuales.** **No** a desnudez, actos sexuales mostrados o descritos y contenido explícito | Nivel Atrevido. Es texto, sin imágenes |
| 5 | Lenguaje: palabrotas / lenguaje fuerte | **No** | Lista negra de insultos en todo el contenido |
| 6 | Humor grosero o soez (si se pregunta aparte) ❓ | **Sí, leve** | Alguna carta Atrevido y Picante (p. ej. gases) |
| 7 | Sustancias controladas: ¿referencias al alcohol? | **Sí** | Modo Sorbos, aunque esté apagado de serie. Contestar No sería una declaración incorrecta |
| 8 | ¿Se muestra o se representa el consumo de alcohol? | **Sí** ❓ | El modo indica "N sorbos". Es texto, sin imágenes ni marcas. Si la pregunta habla solo de imágenes del consumo, contestar según el formulario y anotar la duda |
| 9 | ¿Anima o incita a consumir alcohol? ❓ | **Sí** (recomendado; es lo prudente) | El juego le dice al jugador que beba. Contestar Sí sube la edad hacia 18, que ya es el objetivo. Contestar No es el riesgo de verdad |
| 10 | ¿Glorifica o premia el consumo excesivo? (si existe) ❓ | **No** | Tope de 3 por ronda, alternativa de agua o reto siempre visible y la Copa solo con podio. Es coherente con la política de contenido inapropiado de Google |
| 11 | Drogas / tabaco | **No** | Lista negra |
| 12 | Juegos de azar: ¿azar simulado / apuestas simuladas? | **Sí** | Carrera: se apuestan fichas sin valor sobre el caballo ganador |
| 13 | ¿Apuestas con dinero real, premios reales o moneda canjeable? | **No** | Las fichas no se compran ni se canjean |
| 14 | Interacción entre usuarios / chat / contenido de usuarios | **No** | Todo se juega en un solo móvil, sin red. Los nombres de los jugadores no salen del dispositivo |
| 15 | ¿Comparte la ubicación del usuario? | **No** | — |
| 16 | ¿Permite compras digitales? | **No** | — |
| 17 | ¿Acceso a internet sin restricciones / navegador? | **No** | Solo abre enlaces fijos en el navegador del sistema |
| 18 | ¿Es una app de apuestas reales, citas o chat anónimo? | **No** | — |

**Resultado esperado:** **PEGI 18 probable.** Según los criterios oficiales de PEGI (pegi.info, consultada el 27/11/2026):
- las referencias al alcohol dan como mínimo PEGI 16 (descriptor "Drogas");
- los juegos de azar simulados al estilo casino dan PEGI 18;
- las insinuaciones sexuales solas darían PEGI 12.

❓ No está confirmado que IARC trate una carrera con apuestas de fichas como "casino". Ojo: la página de Google answer/188189 dice que PEGI 12 admite azar simulado, y eso contradice a pegi.info; manda la de PEGI. Si sale PEGI 16, también es aceptable: no inflar las respuestas para forzar el 18. Si sale menos de 16, repasar las filas 7 a 9 y 12.

### Público objetivo y contenido (Play Console)

| Pregunta | Respuesta | Fuente |
|---|---|---|
| Grupos de edad objetivo | **Solo "18 años o más"** (las opciones van de "5 años o menos" a "18 años o más") ✅ | Google, answer/9867159, consultada el 27/11/2026 |
| ¿Puede atraer a menores sin querer? / Detalles de la app (si lo pregunta) ❓ | **No**. Estilo de casino y fiesta adulta, sin personajes infantiles | — |
| Casilla "Restringir el acceso de menores" (Restrict Minor Access) | **Recomendado: activarla.** No es obligatoria para Habinson: la política Age-Restricted la exige a las apps de citas, de apuestas reales y, desde el 26/08/2026, de chat anónimo. Pero es coherente con "+18" y con declarar alcohol | Google, answer/9867159 y la política Age-Restricted Content and Functionality (answer/16302250), consultadas el 27/11/2026 |
| Anuncios | **No contiene anuncios** | — |
| Seguridad de los datos | **No se recogen ni se comparten datos** | Ver `docs/COMPLIANCE.md` #12 |

⚠️ Si se activa "Restringir el acceso de menores", las cuentas de la prueba cerrada (12 testers durante 14 días) tienen que ser de mayores de 18. Avisarlo en `docs/store/mensaje_testers.md`.

---

## (b) App Store · Clasificación por edad (sistema vigente, build sin Sorbos)

### Lo que está confirmado
- ✅ Desde el 24/07/2025 la escala es **4+, 9+, 13+, 16+, 18+**. Hay preguntas nuevas obligatorias (controles en la app, capacidades, temas médicos o de bienestar y violencia), y había que contestarlas antes del **31/01/2026** para poder enviar actualizaciones (Apple Developer News, id=ks775ehf, 24/07/2025).
- ✅ Los nombres de las preguntas y su correspondencia con cada edad salen de "Age ratings values and definitions" (App Store Connect Help, ©2026, sin fecha de revisión, consultada el 27/11/2026).
- ✅ El paso final **"Age Categories and Override"** permite **"Override to Higher Age Rating"**. La tienda muestra la edad elegida, pero los descriptores siguen saliendo de las respuestas ("Set an app age rating", ©2026, consultada el 27/11/2026).
- ❓ Apple no define en la página visible qué cuenta como "Infrequent" y qué como "Frequent".
- ❓ Los nombres en español de App Store Connect pueden variar. Abajo van en inglés, que es como los publica la documentación.

### Paso 1 · In-App Controls

| Pregunta | Respuesta | Por qué |
|---|---|---|
| Parental Controls | **No** | Los niveles Suave/Picante/Atrevido son una elección del grupo, no herramientas para que un tutor controle al menor |
| Age Assurance | **No** | Apple pone como ejemplos la Declared Age Range API, la estimación de edad o la verificación con DNI o pasaporte. El "Tengo 18 o más" de Habinson es una declaración del usuario, no una verificación. Marcar Sí sería inexacto |

### Paso 2 · Capabilities

| Pregunta | Respuesta | Por qué |
|---|---|---|
| Unrestricted Web Access | **No** | Solo enlaces fijos, que se abren fuera de la app |
| User-Generated Content | **No** | Los nombres de jugadores son locales y nadie más los ve |
| Social Media | **No** | — |
| Social Media Disabled for Users Under 13 | **No / no aplica** | — |
| Messaging and Chat | **No** | — |
| Shared Location | **No** | — |
| Advertising | **No** | — |

### Paso 3 · Mature Themes

| Pregunta | Respuesta | Por qué |
|---|---|---|
| Profanity or Crude Humor | **Infrequent** | Humor grosero leve y ocasional, sin insultos (9+) |
| Horror/Fear Themes | **None** | — |
| Alcohol, Tobacco, or Drug Use or References | **None** (solo en la build sin Sorbos) | Con `SORBOS=false` no hay ningún texto de beber al alcance del usuario y el contenido no menciona alcohol. ⚠️ Si alguna vez se envía a Apple una build sin el flag, la respuesta pasa a **Frequent** (18+) y vuelve el riesgo de la 4.3(b) |
| Dating and Relationships | **No / None** | Apple lo define como funciones que ponen en contacto a personas reales para citas o como un compañero virtual romántico o sexual. Habinson no tiene nada de eso. ⚠️ No confundirlo con los temas de ligue de Picante, que van en Mature/Suggestive |

### Paso 4 · Medical or Wellness

| Pregunta | Respuesta |
|---|---|
| Medical or Treatment Information | **None** |
| Health or Wellness Topics | **No** |

### Paso 5 · Sexuality or Nudity

| Pregunta | Respuesta | Por qué |
|---|---|---|
| Mature or Suggestive Themes | **Frequent** | Apple lo define como insinuación sexual o referencias indirectas. Picante, que está activo de serie, y Atrevido están llenos de eso (16+) |
| Sexual Content or Nudity | **Frequent** (recomendado) | Apple incluye aquí la "actividad sexual insinuada". Casi todo Atrevido lo es. "Infrequent" (13+) se puede defender porque viene apagado de serie, pero quedarse corto es el riesgo de la 2.3.6, y declarar de más no cuesta nada si el objetivo ya es 18+ |
| Graphic Sexual Content and Nudity | **None** | Nunca es explícito. Cualquier otra respuesta deja la app como "Unrated", y una app Unrated no se puede publicar en el App Store |

### Paso 6 · Violence

| Pregunta | Respuesta |
|---|---|
| Cartoon or Fantasy Violence | **None** |
| Realistic Violence | **None** |
| Prolonged Graphic or Sadistic Realistic Violence | **None** |
| Guns or Other Weapons | **None** |

### Paso 7 · Chance-Based Activities

| Pregunta | Respuesta | Por qué |
|---|---|---|
| Gambling (dinero real) | **No** | — |
| Simulated Gambling | **Frequent** | Apple lo define como apostar sin dinero real ni moneda canjeable. La Carrera es el primer juego de la home y la estética es de casino (COMPLIANCE R3). Infrequent daría 13+ |
| Contests | **Frequent** | Apple pone de ejemplo las trivias. Trivia, Geografía y el podio de la Copa (13+) |
| Loot Boxes | **No** | — |

### Paso 8 · Age Categories and Override

- Edad calculada esperada: **18+** (Frequent Simulated Gambling y Frequent Sexual Content dan 18+ cada uno).
- Si sale 18+: elegir **Not Applicable**.
- Si sale menos de 18+ (por ejemplo, porque al final se marca Infrequent): **Override to Higher Age Rating → 18+**. La app y la política de privacidad dicen "+18", y la propia Apple dice que se puede subir la edad cuando la política de la app exige más edad.
- **Made for Kids: no** (no está disponible por encima de 9+ y no aplica).
- Age Suitability URL (opcional): se puede dejar vacía, o poner `privacidad.html` si dice "+18".

**Resultado esperado:** 18+ en todas las regiones. En Australia, el azar simulado ya da R 18+ por sí solo (Apple, misma página).

### Otras secciones de App Store Connect (sin cambios)
- Privacidad de la app: "Data Not Collected". Cifrado: `ITSAppUsesNonExemptEncryption = false`.

---

## (c) PEGI

- **No hace falta solicitarlo aparte para Google Play.** PEGI entra en las tiendas digitales a través de IARC, y el cuestionario de Play Console ya devuelve la clasificación PEGI para Europa (Google, answer/9859655 y answer/188189; PEGI, "What do the labels mean?", consultadas el 27/11/2026). ❓ No he encontrado ninguna página de PEGI que diga explícitamente que no hay otra vía para apps. La única que describen las fuentes es IARC.
- **Apple no usa IARC ni PEGI**: aplica su propia escala, también en la UE.
- Una solicitud directa a PEGI solo tendría sentido para una distribución física o en consolas: **no procede**.
- Resultado esperado en Play: **PEGI 18** (o 16), con los descriptores **Sexo** ❓ (con insinuaciones suele ir a 12), **Drogas** (alcohol) y **Juego/Apuestas**.

---

## Riesgos (de más a menos grave)

| # | Nivel | Riesgo | Arreglo propuesto |
|---|---|---|---|
| 1 | ❌ | **Las notas para el revisor de Apple (`docs/store/notas_revisor_apple_en.md`) describen el modo "Sips (Sorbos)"** (líneas 18, 26, 33 y 45), el texto "Nobody is obliged to drink" y un tope de retos anterior a D20. La build de iOS no tiene nada de eso. El revisor vería el alcohol justo donde la 4.3(b) habla de "drinking games", y además las notas no coincidirían con la app | Reescribir las notas para la build sin Sorbos: quitar Sips y beber, y dejar Fichas y Retos. Encargar a `habin:release-movil` o `habin:redactor-es` |
| 2 | ❌ | **La ficha (`docs/store/ficha_es.md`, línea 52) promete "Consecuencias opcionales +18… agua o reto"**, que en iOS no existen. Los metadatos tienen que describir la app real (Apple 2.3) | Hacer una variante de la ficha para iOS sin esa línea. En Android se puede quedar |
| 3 | ⚠️ | **Quedarse corto en alcohol en Android** (filas 7 a 9) o en contenido sexual en Apple. Tergiversar el contenido puede acabar en retirada (Google) o en rechazo (Apple 2.3.6) | Contestar como se propone. Rehacer el cuestionario si se añaden modos o contenido |
| 4 | ⚠️ | **Enviar a Apple una build sin `--dart-define=SORBOS=false`**. Invalida la respuesta "Alcohol: None" | Fijar el flag en `codemagic.yaml` o en el script de build de iOS y comprobarlo en la checklist de publicación |
| 5 | ⚠️ | **"Copa" en español también es una bebida** ("tomar una copa"). Junto con las fichas y el azar, el revisor o IARC pueden leerlo como alusión al alcohol | En la ficha y en las capturas, presentarla siempre con el trofeo y como "marcador". En las notas en inglés, "night's trophy/scoreboard" |
| 6 | ⚠️ | **Estética de casino** (COBRA/PAGA, All-in, fichas): sube la edad (PEGI 18) y atrae la atención del revisor | Ver qué NO mostrar |
| 7 | ❓ | Los textos exactos de IARC no se pueden verificar, y tampoco la correspondencia exacta de la carrera con apuestas en PEGI | Cotejarlo en pantalla, guardar una captura del resumen y el correo del certificado IARC. Si no se está de acuerdo, se recurre ante IARC con el enlace del certificado |

## Qué NO mostrar en la ficha ni en las capturas (las dos tiendas)

- Nada del **modo Sorbos**: ni el selector, ni el banner "N sorbos · o agua o reto", ni el diálogo +18 de Sorbos. En iOS, tampoco en el texto.
- Ninguna **carta Atrevido** ni la palabra "Atrevido". En la ficha se habla de un "modo +18 opcional" genérico, como ya hace `ficha_es.md`.
- Ni **vasos, copas de bebida, botellas o nombres de bebidas**, ni las palabras "beber", "sorbo", "shot" o "drinking game", tampoco en las palabras clave de Apple.
- **Carrera con apuesta visible**: ni "COBRA/PAGA", ni "All-in", ni cantidades de fichas en primer plano. ⚠️ `docs/store/capturas/02_carrera_apuesta.png` va en contra de esto: mejor sustituirla por la pista sin apuestas o pasar la Carrera al final del carrusel.
- Ni "apuesta", "casino" ni "gana" como reclamo. Las fichas "no tienen valor ni se compran" (ya está en la ficha).
- La primera captura con Infiltrado, Trivia, Geografía o los mazos en Suave, y `01_home.png` rehecha en modo Fichas y sin Sorbos (pendiente de Javier).

## Qué requiere a Javier o a un profesional

- **Javier:**
  - rellenar los dos cuestionarios en pantalla cotejando cada fila (sobre todo las marcadas ❓);
  - decidir si activa "Restringir el acceso de menores" en Play;
  - poner un correo real para IARC;
  - rehacer las capturas 01 y 02;
  - pedir que se corrijan las notas para Apple y la ficha de iOS (riesgos 1 y 2).
- **Profesional:** no hace falta para los cuestionarios. Si Apple rechaza por 4.3(b) o 1.4.3, o IARC asigna algo que no encaja, consultar antes de recurrir o reenviar.

## Fuentes (consultadas el 27/11/2026)

- Apple, Age ratings values and definitions (nombres de las preguntas, definiciones y edad por respuesta; ©2026, sin fecha de revisión): https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions
- Apple, Set an app age rating (pasos, "Age Categories and Override", "Override to Higher Age Rating", Unrated; ©2026): https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
- Apple Developer News, actualización de las clasificaciones por edad (24/07/2025; plazo 31/01/2026): https://developer.apple.com/news/?id=ks775ehf
- Apple, App Review Guidelines 1.4.3, 2.3, 2.3.6 y 4.3(b) (sin fecha visible; citadas en `docs/COMPLIANCE.md`, 24/11/2026): https://developer.apple.com/app-store/review/guidelines/
- Google Play, Cuestionario de clasificación de contenido (pasos, PEGI en Europa; ©2026): https://support.google.com/googleplay/android-developer/answer/9859655
- Google Play, Content ratings (exactitud, repetir el cuestionario si cambia el contenido, recursos ante IARC; ©2026): https://support.google.com/googleplay/android-developer/answer/9898843 y https://support.google.com/googleplay/android-developer/answer/188189
- Google Play, Público objetivo y contenido (grupos de edad, Restrict Minor Access; ©2026): https://support.google.com/googleplay/android-developer/answer/9867159
- Google Play, Age-Restricted Content and Functionality (obligatorio para citas, apuestas reales y, desde el 26/08/2026, chat anónimo): https://support.google.com/googleplay/android-developer/answer/16302250
- Google Play, Inappropriate Content (consumo excesivo de alcohol; citado en `docs/COMPLIANCE.md`): https://support.google.com/googleplay/android-developer/answer/9878810
- PEGI, What do the labels mean? (12: insinuación sexual; 16: alcohol/tabaco/drogas; 18: azar simulado al estilo casino; etiquetas en tiendas IARC): https://pegi.info/what-do-the-labels-mean
