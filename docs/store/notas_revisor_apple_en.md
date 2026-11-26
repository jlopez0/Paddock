# App Review notes (App Store Connect · "Notes") · Habinson 1.0

Paste the block below into App Store Connect > App Review Information > Notes. Keep it under 4,000 characters.

```
Habinson is a collection of party games for groups who play together on a single iPhone: Horse Race (card race with chip bets), The Infiltrator (social deduction), Trivia, Geography, Alphabet (one word per letter), Who's Most Likely To, Would You Rather and Never Have I Ever. Results from several games feed a shared, on-device scoreboard for the night ("Copa de la noche"). The app UI and content are in Spanish.

No account, no login
- No sign-up and no demo account needed. All features are available from the first launch.

Network and data
- All game content (including Trivia questions) is bundled with the app. The games work fully offline.
- The only network use is opening the Privacy Policy and Support pages in the external browser, plus the system share sheet when the user shares the night's results (plain text).
- No analytics, no ads, no tracking, no third-party SDKs that collect data. Player names and settings are stored only on the device (shared_preferences).
- No in-app purchases, no subscriptions, no real-money gambling. "Chips" are points with no monetary value and cannot be bought.

Age rating and mature content
- First launch shows a one-time screen: "+18 · Play responsibly · Nobody is obliged to drink".
- Card games and The Infiltrator have three content levels: Mild (Suave), Spicy (Picante, flirting/exes, nothing sexual) and Daring (Atrevido, suggestive innuendo, never explicit: no described sexual acts, nudity or genitals).
- Daring is OFF by default. Turning it on requires an 18+ confirmation dialog.
- Dares (Retos) of the Daring level are only shown after that same confirmation.

Consequences mode (Settings > Consecuencias)
- Points (default): lost chips are subtracted from the scoreboard.
- Dares: one dare per lost chip, max 3 per round. Dares involve no physical risk and no eating or drinking.
- Sips (Sorbos): optional, OFF by default, only available after the 18+ confirmation. Max 3 per round, and the option "swap for water or a dare" is always visible. Drinking is never required, there is no competitive or binge drinking, and no game content mentions alcoholic drinks. The scoreboard always counts chips, whatever the mode.

How to test the 18+ content
1. Launch the app and tap "Entendido" on the welcome screen.
2. On the home screen, open "Yo nunca" (or "¿Quién es más probable?", "¿Qué preferirías?" or "El Infiltrado").
3. Under "NIVEL", tap "Atrevido". A dialog "Solo para mayores de 18" appears. Tap "Tengo 18 o más".
4. Tap "Empezar · N cartas" to play with Daring cards included.
5. To test Sips: tap the gear icon (Ajustes) on the home screen > "Consecuencias" > "Sorbos". If not yet confirmed, the same 18+ dialog appears.
The 18+ confirmation is stored once on the device. To see the dialogs again, delete and reinstall the app.

Attribution
- Some Trivia questions come from Open Trivia DB (opentdb.com), CC BY-SA 4.0, translated and adapted to Spanish. Credited in Settings > Créditos.

Contact
- habinthegreat@gmail.com
```

## Before submitting

- If Apple raises guideline 4.3(b) ("drinking games"), reply pointing to the default Points mode, the scoreboard in chips and the Sips mode being optional, 18+ and capped.
