# How to add a story

Stories live in `Sources/ReadingCore/Passages/`. Each file is JSON. You can add one story per file, or put a list of stories in one file. The app loads every `.json` file in that folder. No code change is required.

After you add or edit a file, run:

```bash
./build.sh test
```

That checks the shape of the stories, the reading level, and the scoring. Fix any lines it prints before you build the app.

## One story

```json
{
  "id": "bell-in-the-fog",
  "title": "The Bell in the Fog",
  "kind": "fiction",
  "level": 1,
  "order": 17,
  "sentences": [
    { "id": "s1", "text": "A bell hung beside a harbor path." },
    { "id": "s2", "text": "Fog hid the rocks, so the keeper rang the bell twice." },
    { "id": "s3", "text": "A boat turned wide and stayed safe." }
  ],
  "questions": [
    {
      "id": "q1",
      "skill": "mainIdea",
      "prompt": "What is this story mostly about?",
      "choices": [
        { "id": "a", "text": "A bell that warns boats in the fog" },
        { "id": "b", "text": "A boat that never leaves the dock" },
        { "id": "c", "text": "A path made of bells" }
      ],
      "answerId": "a",
      "explanation": "The keeper rings the bell because fog hides the rocks, and the boat turns wide. Warning boats is the big idea.",
      "lookBackSentenceIds": ["s2", "s3"]
    }
  ]
}
```

The example above is only a pattern. A real story needs 3 to 5 questions, and the tests also check length. Do not ship a story that short.

## Fields

| Field | What to put |
|---|---|
| `id` | Lowercase words with hyphens, unique, 60 characters or fewer. Example: `bell-in-the-fog`. |
| `title` | The name shown on the map. Must be unique. |
| `kind` | `fiction`, `nonfiction`, `fable`, or `poem`. |
| `level` | `1` Meadow Trail, `2` Whispering Woods, or `3` Starlight Peaks. |
| `order` | A whole number. On one trail, each story needs its own number. The map unlocks them in this order. |
| `attribution` | Required for a fable. Say that it is a retelling of a public-domain fable by Aesop, and that the wording is original. Leave it off for other kinds. |
| `sentences` | At least 3. A poem uses one line per item. Each needs an `id` unique inside the story (`s1`, `s2`, ...) and non-empty `text`. |
| `questions` | 3, 4, or 5 questions. |

## Questions

| Field | What to put |
|---|---|
| `id` | Unique inside the story. `q1`, `q2`, and so on. |
| `skill` | `mainIdea`, `detail`, `vocabulary`, `inference`, or `sequence`. Use each skill only once in the same story. Every story needs one `mainIdea` question. |
| `prompt` | The question, in plain words. |
| `choices` | 3 or 4 answers. Each has an `id` (`a`, `b`, `c`, `d`) and `text`. Do not repeat the same answer. |
| `answerId` | The `id` of the correct choice. |
| `explanation` | A kind explanation of the right idea. At least a full sentence. Do not insult the reader. The app shows this after every answer. |
| `lookBackSentenceIds` | One or more sentence ids. If the answer is missed, those lines light up under the words "Look back in the story." |

## Length

These are the limits the tests enforce:

- Poems: 25 to 180 words.
- Other level 1 stories: 70 to 170 words.
- Other level 2 stories: 110 to 230 words.
- Other level 3 stories: 150 to 320 words.

Words are counted by splitting on spaces, across every sentence or line.

## What the writing should be like

- About a 3rd or 4th grade reading level.
- Original wording. Fables may retell Aesop, who is public domain. Do not paste a copyrighted retelling.
- No real child's name, photo, or personal detail. Do not put a web address in a story.
- Facts in a `nonfiction` story should be accurate.
- The correct choice should not always be the longest one, and it should not always be the first choice.
- Vocabulary questions should use a word that appears in the story. The explanation should say what the word means there.
- Inference questions should use clues, not a sentence that already states the answer word for word.

## A list of stories in one file

A file may instead be a JSON list: `[ { story }, { story } ]`. Mixing both styles in the folder is fine.
