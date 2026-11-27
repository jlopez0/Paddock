# App Review notes (App Store Connect · "Notes") · Habinson 1.0 (iOS)

Paste the block below into App Store Connect > App Review Information > Notes. Keep it under 4,000 characters.

Applies only to the iOS build compiled with `--dart-define=SORBOS=false` (D15). That build has no drinking mode and no drinking texts. If a build without the flag is ever sent to Apple, these notes and the age rating answers (`docs/store/CUESTIONARIOS_EDAD.md`) are no longer valid.

```
Habinson is an offline collection of party games for groups who play together on a single iPhone: Trivia, Geography, The Infiltrator (social deduction), Horse Race (card race with play chips), Alphabet (one word per letter), Who's Most Likely To, Would You Rather and Never Have I Ever. Horse Race and The Infiltrator add or subtract chips on a shared, on-device scoreboard for the night. In Spanish this scoreboard is called "Copa de la noche": "Copa" here means the night's trophy (cup) and leaderboard, with a final podium. The app UI and content are in Spanish.

No account, no login
- No sign-up and no demo account needed. All features are available from the first launch.

Network and data
- All game content (including Trivia questions) is bundled with the app. The games work fully offline.
- The only network use is opening the Privacy Policy and Support pages in the external browser, plus the system share sheet when the user shares the night's results (plain text).
- No analytics, no ads, no tracking, no third-party SDKs that collect data. Player names and settings are stored only on the device (shared_preferences).
- No in-app purchases, no subscriptions, no real-money gambling. "Chips" are points with no monetary value; they cannot be bought or redeemed.

Age rating and optional mature content
- The app is rated 18+. First launch shows a one-time screen: "+18 · Play responsibly · Nobody is obliged to do anything".
- Card games and The Infiltrator have three content levels: Mild (Suave), Spicy (Picante: flirting, exes and jealousy, nothing sexual) and Daring (Atrevido: suggestive innuendo, never explicit; no described sexual acts, no nudity).
- Daring is OFF by default. Turning it on requires an 18+ confirmation dialog.
- Dares (Retos) of the Daring level are only shown after that same confirmation.

What is at stake (Settings > "Qué hay en juego")
- Chips (Fichas, default): lost chips are subtracted from the scoreboard.
- Dares (Retos): one dare per event, stronger the more you lose. Dares involve no physical risk. Horse Race is not available in this mode.
- The scoreboard always counts chips, whatever the mode.

How to test the optional 18+ content
1. Launch the app and tap "Entendido" on the welcome screen.
2. On the home screen, open "Yo nunca" (or "¿Quién es más probable?", "¿Qué preferirías?" or "El Infiltrado").
3. Under "NIVEL", tap "Atrevido". A dialog "Solo para mayores de 18" appears. Tap "Tengo 18 o más".
4. Tap "Empezar · N cartas" to play with Daring cards included.
The 18+ confirmation is stored once on the device. To see the dialog again, delete and reinstall the app.

Attribution
- Some Trivia questions come from Open Trivia DB (opentdb.com), CC BY-SA 4.0, translated and adapted to Spanish. Credited in Settings > Créditos.

Contact
- habinthegreat@gmail.com
```

## Before submitting

- Check that the build was compiled with `--dart-define=SORBOS=false`: the welcome screen must say "Nadie está obligado a nada" and Settings must show only "Fichas" and "Retos".
- If Apple raises guideline 4.3(b) ("drinking games"), reply that the app has no drinking mode or drinking content, that "Copa" is the night's trophy and leaderboard, and that the default mode is Chips, which are points with no value.
