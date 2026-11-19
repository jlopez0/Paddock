# Publicar Paddock en Google Play

## 1. Clave de subida (una sola vez)
En Windows (PowerShell, con el JDK de Android Studio en el PATH):

```
keytool -genkey -v -keystore $env:USERPROFILE\paddock-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Guarda el `.jks` y las contraseñas en **dos sitios** (p. ej. gestor de contraseñas + copia cifrada). Si la pierdes, hay que pedir a Google un reset de la clave de subida.

## 2. `android/key.properties` (no se versiona)
```
storePassword=<contraseña>
keyPassword=<contraseña>
keyAlias=upload
storeFile=C:\\Users\\<usuario>\\paddock-upload.jks
```

## 3. Compilar
```
flutter clean
flutter pub get
flutter build appbundle --release
```
Sale en `build/app/outputs/bundle/release/app-release.aab`.

## 4. Play Console
- Crear la app con el ID `es.jlopez0.paddock` (definitivo).
- Activar **Play App Signing** (Google guarda la clave de firma; tú, la de subida).
- Subir primero a **Prueba interna** y revisar avisos (target API, 16 KB).
- Después **Prueba cerrada** con 15–20 testers durante 14 días seguidos.

## 5. Páginas públicas
La carpeta `docs/` se publica con GitHub Pages (Settings → Pages → Deploy from branch → `main` / `/docs`):
- Privacidad: https://jlopez0.github.io/Paddock/privacidad.html
- Soporte: https://jlopez0.github.io/Paddock/soporte.html
Antes, sustituye `CORREO_DE_CONTACTO` por el correo de soporte.
