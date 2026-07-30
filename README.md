# still

A quiet, offline-first gratitude journal. One page a day.

No account. No cloud. No analytics. No ads. The app requests no `INTERNET`
permission, so "nothing leaves your device" is enforced by the manifest rather
than promised in a privacy policy.

## What it does

- **One entry per calendar day**, autosaved as you type
- **Calendar** with entry markers; past days open for reading or writing, future days don't
- **Live search** across titles and content
- **Statistics** — total, current streak, longest streak, this month, this year, plus a 12-week heatmap
- **Light / dark / system** themes with a choice of accent colour, applied instantly
- **Daily reminder** scheduled locally
- **Export** to Markdown, JSON or plain text through the system share sheet
- **Import** from a previous JSON export, merging rather than overwriting

## Stack

Flutter · Drift (SQLite) · Riverpod · GoRouter · Material 3

## Running it

```bash
flutter pub get
dart run build_runner build   # generates lib/database/database.g.dart
flutter run
```

Requires the Flutter stable channel. After changing the Drift schema in
`lib/database/database.dart`, re-run `build_runner`.

```bash
flutter test        # unit tests for streak, heatmap and date logic
flutter analyze
```

## Layout

```
lib/
  app/           providers, router, root widget
  core/          theme tokens, typography, date formatting
  database/      Drift schema (+ generated .g.dart)
  models/        JournalEntry, JournalStats, AppSettings
  repositories/  all queries and writes
  services/      preferences, notifications, export/import
  features/      one folder per screen
  widgets/       shared design-system widgets
```

### Adding an accent colour

Append one entry to `lib/core/theme/accents.dart`:

```dart
Accent(
  id: 'ochre',
  label: 'Ochre',
  light: Color(0xFFB8860B),
  dark: Color(0xFFD9A83C),
),
```

The Settings picker and the theme both read from that registry, so it appears
immediately and applies without a restart.

Two constraints: `id` is what gets persisted, so never change it for an existing
accent or you will reset that user's choice. And each accent needs both a light and
a dark value — one hex reused for both will fail contrast in one mode.

The default accent is set by `AccentRegistry.defaultId`.

## Typography

Newsreader is vendored as a variable font rather than fetched at runtime, so the
app stays fully offline. Used under the SIL Open Font License 1.1 —
`assets/fonts/OFL.txt`.
