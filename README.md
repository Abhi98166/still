# still

A quiet gratitude journal. One page a day, offline.

No account, no cloud, no analytics, no ads. There's no `INTERNET` permission in
the manifest, so the app can't phone home even if it wanted to.

The one exception is the backup folder, which writes your entries somewhere you
choose. Read that section before turning it on.

## What it does

- One entry per day, autosaved while you type
- Calendar marking the days you wrote. Past days open, future ones don't
- Search across titles and content
- Stats: totals, current and longest streak, this month, this year, 12-week heatmap
- Light, dark and system themes, with a few accent colours
- A daily reminder, scheduled on-device
- Export to Markdown, JSON or text via the share sheet
- Import from a JSON export. Merges, won't clobber days you already have
- Backup folder, Android only, off by default. Restores from one too

## Backup folder

Turn it on in Settings and pick a folder. still puts this in it:

```
<your folder>/still/
  manifest.json
  entries/2026/2026-08-01.md
```

One file per day with frontmatter at the top, so any day stands on its own.
Obsidian reads them fine.

`manifest.json` records when each day last changed. That's how still knows to
rewrite one file instead of the whole journal, and to write nothing at all when
nothing changed, which keeps Syncthing quiet. It lives in the folder rather than
in app settings, so restoring the folder onto a new phone picks up where you left
off instead of starting over.

Backups run a few seconds after you write, and again when you reopen the app.
There's no background service. Entries only change while the app is open, so
there'd be nothing for one to do.

To go the other way, use Restore from folder under Your data. Point it at the
folder and still reads every day file it finds, keeping the newest copy if a day
turns up twice. Days you already have are left alone unless you say to replace
them. You can hand it the folder holding `still`, the `still` folder itself, or a
directory of loose day files, and it'll work out which you meant — a folder
synced onto a new phone rarely lands at the same depth it left.

Worth knowing before you turn it on: a folder outside app-private storage is
readable by any app with storage permission, and these files are plain text.
Encrypting them would defeat the point, since you want your sync tool and your
text editor to read them. If that's not a trade you want, leave it off and use
the share-sheet export when you need a copy.

## Stack

Flutter, Drift (SQLite), Riverpod, GoRouter, Material 3.

## Running it

```bash
flutter pub get
dart run build_runner build   # generates lib/database/database.g.dart
flutter run
```

Needs the Flutter stable channel. Re-run `build_runner` after any change to the
Drift schema in `lib/database/database.dart`.

```bash
flutter test
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
  services/      preferences, notifications, export/import, folder backup
  features/      one folder per screen
  widgets/       shared design-system widgets
```

The only platform code is in `MainActivity.kt`: a method channel over the Storage
Access Framework, because no Flutter plugin can hold onto a folder permission
across launches.

### Adding an accent colour

Add an entry to `lib/core/theme/accents.dart`:

```dart
Accent(
  id: 'ochre',
  label: 'Ochre',
  light: Color(0xFFB8860B),
  dark: Color(0xFFD9A83C),
),
```

Settings and the theme both read from that registry, so it shows up straight away
without a restart.

Two things to watch. Don't change the `id` of an accent that's already shipped,
because that's what gets persisted and you'll reset the choice of anyone using
it. And give every accent both a light and a dark value: one hex reused for both
will fail contrast in one mode or the other.

The default is `AccentRegistry.defaultId`.

## Typography

Newsreader, vendored as a variable font rather than fetched at runtime so the app
stays offline. Used under the SIL Open Font License 1.1, see
`assets/fonts/OFL.txt`.
