# Publicar Habinson en Google Play

## 1. Clave de subida (una sola vez, la creas tú)
Claude no la genera ni la ve: las contraseñas son solo tuyas.

1. Abre PowerShell (no hace falta ser administrador).
2. `keytool` viene con Android Studio. Si `keytool` no se reconoce, usa la ruta completa (en esta máquina existe `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`):

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v `
  -keystore "$env:USERPROFILE\habinson-upload.jks" `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

3. Te pedirá: contraseña del almacén (mínimo 6 caracteres), nombre/organización/país (puedes poner tu nombre y `ES`) y contraseña de la clave (Enter = la misma que la del almacén; es lo más simple). Apunta la contraseña en tu gestor de contraseñas antes de seguir.
4. Verifica que se creó y que la contraseña funciona:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -keystore "$env:USERPROFILE\habinson-upload.jks"
```

5. **Backup** (obligatorio): copia `habinson-upload.jks` a como mínimo dos sitios fuera del PC (gestor de contraseñas con adjuntos, USB cifrado o nube privada cifrada) y guarda con él: contraseña, alias `upload` y la ruta. Nunca en git, correo ni chat. Si la pierdes, con Play App Signing se puede pedir a Google un reset de la clave de subida, pero tarda días.

## 2. `android/key.properties` (no se versiona)
Crea el archivo `android\key.properties` (ya está en `.gitignore`, igual que `*.jks` y `*.keystore`):

```
storePassword=<contraseña del almacén>
keyPassword=<contraseña de la clave>
keyAlias=upload
storeFile=C:/Users/<usuario>/habinson-upload.jks
```

Detalles: barras invertidas dobles (o barras normales `C:/Users/...`), sin comillas ni espacios sobrantes al final de línea. Comprobación: `git status` no debe mostrar `key.properties` ni el `.jks`.

## 3. Compilar
```powershell
flutter clean
flutter pub get
flutter build appbundle --release --no-tree-shake-icons
```
Sale en `build/app/outputs/bundle/release/app-release.aab`. Sin `key.properties` Gradle firma con la clave debug y Google Play lo rechazará. Para confirmar que lleva tu clave:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```
El "Propietario" debe ser el que escribiste en el paso 1, no `Android Debug`.

## 4. Play Console
- Crear la app con el ID `es.jlopez0.habinson` (definitivo).
- Activar **Play App Signing** (Google guarda la clave de firma; tú, la de subida).
- Subir primero a **Prueba interna** y revisar avisos (target API, 16 KB).
- Después **Prueba cerrada** con 15–20 testers durante 14 días seguidos.

## 5. Páginas públicas
La carpeta `docs/` se publica con GitHub Pages (Settings → Pages → Deploy from branch → `main` / `/docs`):
- Privacidad: https://jlopez0.github.io/Habinson/privacidad.html
- Soporte: https://jlopez0.github.io/Habinson/soporte.html
El correo de contacto (habinthegreat@gmail.com) ya está puesto en privacidad.html y soporte.html.
