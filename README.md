# Reading Quest

Reading Quest is a Mac app for a reader about 9 years old (around 3rd or 4th grade). It is a short-story game: read a passage, answer a few questions, earn stars, and walk a map of three trails. The app ships with 43 passages.

It works offline. There is no account, no ad, and no network. The optional player name starts blank and stays on this Mac.

Bundle id: `com.kidscomputer.reading`

## Download and install

When a release is published, the universal app is on the GitHub releases page:

https://github.com/matjns/kids-reading/releases/latest

Download `ReadingQuest-mac-universal.zip`. It contains `Reading Quest.app` and `README-mac.txt`. The app is unsigned, the same way a home Mac build is shipped. If macOS says it cannot check the app, follow `README-mac.txt` (Control-click, Open, or `xattr -cr`).

You need macOS 14 or newer. The app runs on Apple silicon and on Intel Macs.

## How to play

1. Open Reading Quest. Leave the name blank, or type one if you want. It is saved only on this Mac.
2. Start on the Meadow Trail. Each stop is a story, a fable, a poem, or a short page of real facts.
3. Read it yourself, or press **Read to me**. The Mac speaks with its own voice. Nothing is sent off the computer.
4. Answer 3 to 5 questions. Press 1, 2, 3, or 4, or tap a choice. Return goes to the next question after you answer.
5. If a choice does not match, the app says "Let's look back in the story" and lights up the lines that help.
6. Finishing a story earns 1, 2, or 3 stars. Three stars means every question matched. You can replay to improve.
7. The adventure map unlocks the next stop. Badges and a progress screen keep the stars, the trails, and the recent stories.

The quest also changes the suggested trail. Easy questions open a richer trail. A steep stretch steps back to a gentler one. Trails that are already open stay on the map.

## Kids Computer launcher

This app is a tile for the Kids Computer launcher (`com.kidscomputer.launcher`). The launcher starts it by bundle id `com.kidscomputer.reading`. It also runs on its own from the Applications folder.

Command-Q, or closing the last window, quits normally so the launcher can return. Reading Quest does not hide itself, lock the dock, or quit other apps.

## Where progress is saved

The app writes `progress.json` in Application Support, in a folder named `Reading Quest`.

- Without the sandbox, that is `~/Library/Application Support/Reading Quest/progress.json`.
- The shipped app is sandboxed, so macOS keeps the same folder inside the app container: `~/Library/Containers/com.kidscomputer.reading/Data/Library/Application Support/Reading Quest/progress.json`.

The name field is optional and blank until someone types one. Progress, Start over, erases that file.

## Add a story

Put a new JSON file in `Sources/ReadingCore/Passages/`. The format, the question skills, and the length limits are in [docs/PASSAGE_FORMAT.md](docs/PASSAGE_FORMAT.md). Then run `./build.sh test`.

The stories shipped here are original, except the fables, which are retellings of public-domain Aesop. Those files say so in `attribution`.

## Build on a Mac

Install Xcode, or at least the Xcode command line tools. Then, in this folder:

```bash
./build.sh test
./build.sh
```

`./build.sh test` checks the stories, stars, trails, and badges.

`./build.sh` compiles a universal app into `dist/Reading Quest.app` and zips it as `dist/ReadingQuest-mac-universal.zip`. The first command needs a Mac. The test command also runs anywhere Swift is installed, because the scoring code does not use the Mac interface.

GitHub Actions (`.github/workflows/macos.yml`) runs the tests and the app build on every push and pull request. A version tag such as `v1.0.0`, or a manual run of the workflow, publishes the zip and `README-mac.txt` on the releases page.

## App Store

The app is set up so it can be submitted later: sandbox, icon, version, privacy manifest, and no collected data. The clicks still left are in [docs/APP_STORE.md](docs/APP_STORE.md).

## License

MIT. Copyright 2026 matjns. See [LICENSE](LICENSE).
