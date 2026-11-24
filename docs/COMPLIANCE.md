# Cumplimiento antes de publicar · Paddock v1.0

Revisión del 24/11/2026 (rama `fase-0-publicacion`). **Esto no es asesoría legal ni fiscal**: es una lista de riesgos para decidir qué conviene consultar con un profesional.

Leyenda: 🔴 bloquea o tiene riesgo serio · 🟡 conviene arreglarlo antes de publicar · 🟢 correcto o riesgo bajo. Estado por punto: ✅ cumple · ⚠️ riesgo · ❌ incumple · ❓ no verificable.

## Tabla de riesgos (de más a menos grave)

| # | Nivel | Riesgo | Qué hacer | Archivo afectado |
|---|---|---|---|---|
| 1 | 🔴 ❌ | La política de privacidad y la página de soporte tienen `CORREO_DE_CONTACTO` sin sustituir y no dicen quién es el responsable. Google exige que la política incluya los datos del desarrollador, un contacto de privacidad y el mismo nombre que aparece en la ficha. Además, la URL tiene que estar publicada (GitHub Pages) antes de enviar la app. | Poner el nombre del desarrollador (el mismo de la ficha) y un correo real, y activar Pages. Comprobar que `kPrivacyUrl` abre la página. | `docs/privacidad.html`, `docs/soporte.html`, `lib/app/app_info.dart` |
| 2 | 🔴 ⚠️ mitigado (2026-11-24) | **Abecedario**: el nombre y el círculo ya no aparecen, pero se mantienen las pistas "Empieza por X / Contiene la X" y el avance por letras con tiempo. En mayo de 2026 el Tribunal Supremo confirmó que la mecánica de "El Rosco" está protegida por propiedad intelectual (titular: MC&F), y "El Rosco" es marca de ITV en la UE. La probabilidad de reclamación a una app pequeña es baja, pero las consecuencias pueden ser serias. | Arreglo sencillo: cambiar la redacción de las pistas (p. ej. "Letra X", "Con X al principio" / "Lleva una X"), mantener la cuadrícula y no usar "Rosco", "Pasapalabra" ni sus colores o sonidos en la ficha ni en las capturas. Si se quiere conservar la mecánica tal cual, **consultar con un abogado de propiedad intelectual**. Verificar a mano que las 330 definiciones son propias (❓: no se pueden comprobar desde aquí). | `lib/games/abecedario/abecedario_data.dart` (línea 53), `assets/content/es/abecedario.json` |
| 3 | 🔴 ⚠️ (App Store) | Apple pone los "drinking games" como ejemplo de apps de poco valor en la 4.3(b) y prohíbe animar a consumir alcohol en exceso (1.4.3). Los textos "Nadie está obligado a beber" de la bienvenida y de Créditos se ven aunque el modo Sorbos esté desactivado, y eso llama la atención del revisor. En Google Play el riesgo es menor (ver #6). | Para iOS: lo más seguro es quitar el modo Sorbos de la compilación de iOS (con un flag) y dejar en la bienvenida solo "Juega con responsabilidad". En las notas para el revisor, explicar que es un recopilatorio (Trivia, Geografía, Infiltrado, Copa) y que no hay alcohol por defecto. Capturas sin alcohol. | `lib/app/welcome_screen.dart`, `lib/app/credits_screen.dart`, `lib/app/settings_screen.dart` |
| 4 | 🟡 ✅ resuelto (2026-11-24) | La política dice que los datos "nunca salen del dispositivo", pero Android hace por defecto una copia de seguridad de `shared_preferences` en el Google Drive del usuario (`android:allowBackup` no está declarado, así que vale `true`). La política además solo menciona nombres y ajustes, cuando también se guardan la Copa (puntuaciones por jugador), las estadísticas y el progreso de los juegos. | Lo más simple es añadir a la política que se guardan "nombres, ajustes, marcador de la noche y estadísticas", y que Android puede incluirlos en la copia de seguridad del usuario. Otra opción es poner `android:allowBackup="false"`. Añadir también un apartado de conservación y borrado (Google y Apple 5.1.1 lo piden). | `docs/privacidad.html`, `android/app/src/main/AndroidManifest.xml` |
| 5 | 🟡 ⚠️ | Cuestionarios de edad: hay que declarar las referencias a alcohol (modo Sorbos y textos) y las referencias sexuales sugeridas (nivel Atrevido). Apple cambió su sistema en 2025 (4+, 9+, 13+, 16+, 18+, con preguntas nuevas obligatorias). El resultado de IARC/PEGI es ❓ hasta rellenar el cuestionario. | Contestar con sinceridad (2.3.6). En Play Console, público objetivo solo 18+. Para la v1.0, publicar solo en España para reducir el número de normativas locales. | Play Console / App Store Connect, `docs/CONTENIDO.md` (ya lo dice) |
| 6 | 🟡 ⚠️ | Google Play no permite presentar de forma favorable el consumo excesivo, en atracón o en competición. Sorbos está desactivado por defecto, pide confirmar +18, tiene un tope de 3 por ronda y siempre ofrece la alternativa de agua o reto, y el All-in se limita a 3. Parece suficiente, pero lo decide el revisor. | Mantener los topes y no mostrar alcohol en la ficha ni en las capturas. No hay que cambiar código. | `lib/core/consequences/` |
| 7 | 🟡 ⚠️ | Contenido Atrevido (p. ej. "esposas", "striptease"): es sugerente, no explícito, así que encaja en Google (prohíbe lo explícito y el lenguaje obsceno) y en Apple 1.1.4. | Mantener la lista negra del test. Nada de Atrevido en la ficha ni en las capturas (ya está en el plan). | `assets/content/es/*.json`, `test/content_test.dart` |
| 8 | 🟡 ✅ resuelto (2026-11-24) | Las licencias de los paquetes (BSD-3 y MIT, incluidos Flutter y `material_ui`) obligan a reproducir el aviso de copyright, y la app no tiene una pantalla de licencias. | Añadir en Ajustes o Créditos "Licencias de código abierto" con `showLicensePage()`, que reúne automáticamente las de todos los paquetes. | `lib/app/settings_screen.dart` o `credits_screen.dart` |
| 9 | 🟡 ⚠️ mitigado (2026-11-24) | Trivia CC BY-SA 4.0: la atribución en la app indica la fuente, la licencia y que hay cambios, pero no enlaza a la licencia, y la 3(a) lo pide. Compartir igual (3(b)): las 48 preguntas `ot-` traducidas son material adaptado y tienen que distribuirse con CC BY-SA 4.0 sin restricciones añadidas. Las preguntas originales **no** quedan afectadas: juntarlas en un fichero no las convierte en adaptación, y 48 de las miles de OpenTDB no es una "parte sustancial" de la base de datos (Sección 4). En iOS, el DRM de la tienda podría chocar con la prohibición de restricciones técnicas (zona gris). | Añadir el enlace creativecommons.org/licenses/by-sa/4.0 en Créditos. Publicar las preguntas `ot-` traducidas en `docs/` (p. ej. `trivia-opentdb.json` con su licencia), lo que también resuelve lo del DRM. Indicar en `docs/CONTENIDO.md` que solo las `ot-` son CC BY-SA. | `lib/app/credits_screen.dart`, `assets/content/es/trivia.json`, `docs/` |
| 10 | 🟡 ⚠️ | Baraja "Naipes Libres" (CC BY-SA 3.0, recortada): la atribución es correcta, pero falta el enlace a la página del archivo en Wikimedia, y las cartas recortadas también son material adaptado con compartir igual. Falta un registro del origen de los assets en el repositorio. | Añadir la URL del archivo de Commons en Créditos y crear `assets/CREDITS.md` (origen, autor, licencia y enlace de cada asset, incluido el icono). Publicar las cartas recortadas con la misma licencia (por ejemplo, en `docs/`). | `lib/app/credits_screen.dart`, `assets/cards/` |
| 11 | 🟢 ❓ | Nombre "Paddock": no se ha encontrado ninguna app de juegos de fiesta con ese nombre en Google Play ni en el App Store. Sí hay marcas y apps con ese nombre en otros sectores (PaddockPal en el Reino Unido, clase 9; PADDOCK PRO en EE. UU.; Paddock 3.0, de bolos). Es una palabra común del motor y la hípica. | Antes de invertir en la marca, buscar "Paddock" en TMview/EUIPO y en la OEPM, clases 9, 28 y 41. No usar logos ni estética de la F1 ("Paddock Club"). | Ficha de tienda, icono |
| 12 | 🟢 ✅ | Permisos: el manifiesto principal no declara ninguno (INTERNET solo en debug/profile). `share_plus` comparte texto a petición del usuario y Google no lo cuenta como compartir datos en la sección de seguridad de datos. `url_launcher` abre el navegador. ❓ Falta confirmar el manifiesto final de release (`audioplayers`). | Revisar los permisos del AAB en Play Console (App bundle explorer). Sección de seguridad de datos: "no se recogen ni comparten datos". | `android/app/src/main/AndroidManifest.xml` |
| 13 | 🟢 ✅ | iOS: `PrivacyInfo.xcprivacy` declara UserDefaults con el motivo CA92.1, sin seguimiento y sin datos recogidos. Es coherente con el código. | Nada. | `ios/Runner/PrivacyInfo.xcprivacy` |
| 14 | 🟢 ✅ | Otros assets: Natural Earth (dominio público), banderas de flagcdn/Flagpedia (dominio público según Flagpedia, que pide un enlace), Guillermo Tell en la grabación de la Banda de la Marina de EE. UU. (obra del gobierno federal, dominio público en EE. UU.). No hay fuentes propias. | Opcional: añadir el enlace a flagpedia.net en Créditos. | `lib/app/credits_screen.dart` |
| 15 | 🟢 ❓ | Cuenta personal de Google Play: hace falta una prueba cerrada con al menos 12 testers durante 14 días seguidos. Declarar si eres comerciante o no según la DSA: en Apple es obligatorio para distribuir en la UE; en Google, según fuentes no oficiales, el plazo es principios de 2027 (❓). | Sin cobros, "no comerciante" es lo coherente. Comprobarlo en Play Console. | Play Console / App Store Connect |

## Notas por área

**Tiendas.**
- ✅ El alcohol es opcional, tiene tope y alternativa, y pide confirmar +18.
- ⚠️ En Apple, 4.3(b) y 1.4.3 (#3).
- ✅ El contenido sexual es sugerente, nunca explícito.
- ⚠️ Cuestionarios de edad (#5).

**Privacidad / RGPD.**
- No hay cuentas, red, analítica ni SDK de terceros. Los nombres que el usuario escribe se quedan en su dispositivo y el desarrollador nunca accede a ellos. El riesgo RGPD real es bajo.
- Lo que falla es la exactitud de la política (#1, #4), y eso es lo que miran las tiendas.

**Licencias.**
- #8, #9 y #10 se resuelven con texto en Créditos y archivos publicados en `docs/`.
- La duda de fondo es el Abecedario (#2).

**Monetización (no hay cobros; solo lo que cambiaría).** Orientativo; **consultar con un gestor antes de cobrar**:
- **Compras dentro de la app.** Google Play Billing y Apple IAP son obligatorios para contenido digital. Habría que actualizar la política de privacidad y la sección de seguridad de datos.
- **DSA.** Al vender, probablemente pasarías a ser "comerciante", y las tiendas mostrarían públicamente tu dirección, teléfono y correo.
- **Alta de autónomo (RETA).** Depende de la habitualidad de los ingresos.
- **IVA.** Las tiendas suelen actuar como revendedoras ante el consumidor y cobran el IVA al usuario. Tú facturarías a sus filiales de la UE (Irlanda/Luxemburgo), lo que implica operaciones intracomunitarias (registro ROI, modelos 303/349).
- **Comprobar con un profesional** antes de activar cualquier cobro.

## Fuentes (consultadas el 24/11/2026)
- Apple, App Store Review Guidelines (1.1.4, 1.4.3, 2.3.6, 4.3(b), 5.1.1): https://developer.apple.com/app-store/review/guidelines/ (la página no muestra fecha).
- Apple, nuevas clasificaciones por edad (julio de 2025): https://developer.apple.com/news/?id=ks775ehf y https://developer.apple.com/help/app-store-connect/reference/age-ratings
- Apple, estado de comerciante en la UE (DSA): https://developer.apple.com/news/?id=einwn76m
- Google Play, Inappropriate Content: https://support.google.com/googleplay/android-developer/answer/9878810 (sin fecha; ©2026).
- Google Play, User Data (requisitos de la política de privacidad): https://support.google.com/googleplay/android-developer/answer/10144311
- Google Play, sección de seguridad de datos (excepciones por acción del usuario y por procesamiento en el dispositivo): https://support.google.com/googleplay/android-developer/answer/10787469
- Google Play, requisitos de prueba para cuentas personales nuevas: https://support.google.com/googleplay/android-developer/answer/14151465
- Android, Auto Backup (`allowBackup` es `true` por defecto; incluye shared preferences): https://developer.android.com/identity/data/autobackup
- Creative Commons BY-SA 4.0, texto legal (3(a), 3(b), Sección 4): https://creativecommons.org/licenses/by-sa/4.0/legalcode.en
- Open Trivia DB, licencia de los datos: https://opentdb.com/api_config.php
- Flagpedia, licencia: https://flagpedia.net/about
- `material_ui` (BSD-3-Clause, flutter.dev): https://pub.dev/packages/material_ui
- El Rosco: Reason Why, 21/05/2026 (actualizado el 15/06/2026): https://www.reasonwhy.es/actualidad/sentencia-tribunal-supremo-cesar-emision-rosco-pasapalabra ; Economist & Jurist sobre la marca de ITV: https://www.economistjurist.es/actualidad-juridica/la-justicia-europea-confirma-que-la-marca-el-rosco-de-pasapalabra-pertenece-a-itv/ (fuentes de prensa, no las resoluciones originales: ❓ verificar).
- Marcas "Paddock": UKIPO, PaddockPal UK00004198831 (https://www.ipo.gov.uk/t-tmj/tm-journals/2025-021/UK00004198831.html); USPTO, PADDOCK PRO 99123608 (https://trademark.justia.com/991/23/paddock-99123608.html).
