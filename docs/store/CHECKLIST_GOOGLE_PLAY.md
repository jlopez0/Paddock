# Checklist Google Play – Habinson (es.jlopez0.habinson)

Orden de pasos para Javier. Respuestas según el código real (sin red propia, sin cuentas, sin anuncios; datos solo en `shared_preferences` local; `share_plus` y `url_launcher` solo abren diálogos/navegador del sistema).

## 0. Antes de nada (local)
- [ ] Generar keystore de subida y crear `android/key.properties` (NO en git; ya está en `.gitignore`). Ver `docs/PUBLICAR_ANDROID.md`.
- [ ] Guardar copia del keystore + contraseñas en gestor de contraseñas (si se pierde, solo se recupera vía soporte de Google).
- [x] `flutter build appbundle --release --no-tree-shake-icons` compila (2026-11-25, 63,0 MB, firmado con debug por falta de `key.properties`). Repetir tras crear la clave.
- [ ] Confirmar que el AAB sale firmado con la clave de subida (no la debug).
- [ ] Confirmar que https://jlopez0.github.io/Habinson/privacidad.html y `soporte.html` cargan (GitHub Pages activo, carpeta `/docs`).

## 1. Cuenta de desarrollador (requiere Javier: pago y verificación)
- [ ] Cuenta de Play Console (pago único 25 USD, verificación de identidad).
- [ ] Anotar tipo: **personal** (creada tras 13/11/2023) => exige prueba cerrada con >=12 testers durante 14 días continuos antes de pedir producción. **Organización** => no aplica.

## 2. Crear la app
- [ ] Nombre: Habinson. Idioma predeterminado: español (España).
- [ ] Tipo: **Juego** (categoría Fiesta/Trivia o similar). Gratuita.
- [ ] Aceptar declaraciones (políticas del programa, leyes de exportación de EE. UU.).
- [ ] Activar Play App Signing (por defecto) y subir con la clave de subida.

## 3. Contenido de la app (Política > Contenido de la app)
- [ ] **Política de privacidad**: `https://jlopez0.github.io/Habinson/privacidad.html`
- [ ] **Anuncios**: marcar **No contiene anuncios**.
- [ ] **Acceso a la app**: todo accesible sin login; marcar "Toda la funcionalidad está disponible sin restricciones". (La pantalla de bienvenida +18 no es un acceso con credenciales.)
- [ ] **Público objetivo y contenido**: solo **18 años o más**. Ni "menores" ni mixto. Al no incluir menores, no aplica Familias.
- [ ] **Clasificación de contenido (IARC)**: cuestionario con categoría Juego/Fiesta. Responder según contenido real de los mazos:
  - Violencia: No.
  - Contenido sexual: **Sí, referencias sexuales sugeridas** (nivel Atrevido, sin contenido explícito, tras confirmación +18; ver `docs/CONTENIDO.md`). Resultado esperable: 18+, coherente con el público objetivo.
  - Alcohol: **Sí** (referencia y uso representado) por el modo opcional Sorbos (+18, tope 3 por ronda, "agua o reto" visible). Si pregunta si fomenta/instruye a beber: **Sí** (la mecánica indica sorbos). Drogas y tabaco: No. Ver `docs/store/cuestionarios.md`. Esperable PEGI 18.
  - Juegos de azar: **Sí, azar simulado** (fichas/All-in/Copa ficticias). No a dinero real, premios y compras in-app.
  - Interacción de usuarios / compartir ubicación / compras digitales: **No** (compartir texto con share_plus es del sistema; no hay chat ni contenido generado por usuarios hacia terceros).
  - Cuestionario con respuesta honesta: no subestimar contenido, Google puede rechazar la app.
- [ ] **Seguridad de los datos (Data safety)**:
  - ¿Recopila o comparte datos de usuario requeridos? **No**.
  - Dato: preferencias/puntuaciones se guardan solo en el dispositivo (`shared_preferences`), no se transmiten: no cuenta como recopilación.
  - Sin SDK de analítica, publicidad, crash reporting ni backend (verificado: sin dependencia `http`/firebase en `pubspec.yaml`).
  - ¿Cifrado en tránsito? No aplica (sin transmisión). ¿Mecanismo de borrado? No aplica (desinstalar borra los datos locales).
  - Debe ser coherente con `privacidad.html`.
- [ ] **Aplicación de gobierno**: No.
- [ ] **Servicios financieros**: No ofrece.
- [ ] **Salud**: No.
- [ ] **ID de publicidad (AD_ID)**: **No** usa. Manifest fusionado del release verificado sin AD_ID (2026-11-25); confirmar en el informe de Play tras subir el AAB.
- [ ] **Apps de noticias**: No. **Seguimiento de COVID**: No.
- [ ] **Permisos sensibles**: ninguno declarado en el Manifest (ver abajo).

## 4. Ficha de tienda (Presencia en Play Store > Ficha principal)
- [ ] Descripción corta (<=80 car.) y larga (<=4000) en español (usar agente `redactor-es`). Sin menciones a otras marcas, sin "mejor/nº1", sin promesas de ganar dinero, sin referencias a apuestas reales.
- [x] Icono 512x512: `docs/store/graficos/icono_512.png`. Gráfico de funciones 1024x500: `docs/store/graficos/grafico_funciones_1024x500.png` (generados con la P dorada y Alfa Slab One; revisar a ojo).
- [ ] >=2 capturas de móvil (idealmente 4-8).
- [ ] Categoría, correo de contacto público (el de soporte), web (GitHub Pages).
- [ ] Si se pide: capturas de tablet 7"/10" (opcional salvo para ciertas funciones).

## 5. Prueba cerrada (Pruebas > Prueba cerrada)
- [ ] Crear pista de prueba cerrada y lista de testers (correos Gmail o Google Group). **>=12 testers con opt-in** (si cuenta personal nueva), mantenerlos **14 días continuos**.
- [ ] Países: España (+ los que quieras).
- [ ] Subir el AAB (versión `1.0.0+1`; cada nueva subida necesita `+build` mayor).
- [ ] Notas de la versión (es-ES).
- [ ] Enviar a revisión (**requiere tu OK explícito**) y compartir el enlace de opt-in con los testers.
- [ ] Pedir a los testers que instalen y NO desinstalen durante los 14 días.
- [ ] Pasados 14 días: "Solicitar acceso a producción" y responder el cuestionario (cómo hiciste la prueba, comentarios recibidos).

## 6. Producción
- [ ] Tras aprobación del acceso, crear versión de producción con el mismo AAB (o uno nuevo con build mayor).
- [ ] Despliegue escalonado opcional; revisar Pre-launch report y Android vitals.

## Verificación técnica (estado al 2026-11-24)
- applicationId `es.jlopez0.habinson` (namespace interno `com.habinson.habinson`, distinto a propósito).
- compileSdk 36 y targetSdk 36 OK.
- Versión `1.0.0+1`.
- `android:enableOnBackInvokedCallback="true"` presente.
- Manifest fusionado del release (2026-11-25, `build/app/intermediates/merged_manifests/release`): sin `INTERNET`, sin AD_ID, sin permisos de audioplayers/share_plus/url_launcher. Único `uses-permission`: `es.jlopez0.habinson.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (permiso propio de AndroidX, firma local, no se declara en Play). `queries`: solo PROCESS_TEXT de Flutter. minSdk 24, targetSdk 36, `enableOnBackInvokedCallback="true"`.
- `key.properties`, `*.jks`, `*.keystore` ignorados por git.
- Aviso: sin `key.properties` el build usa la clave debug y Play rechazará ese AAB.
- Aviso de build: Flutter avisa de que `audioplayers_android` aplica Kotlin Gradle Plugin (futuras versiones de Flutter exigirán Built-in Kotlin). No bloquea hoy; vigilar actualización del plugin.
