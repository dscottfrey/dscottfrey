# `scripts/kanban/` — driving the Reminders board

The live board is the Apple Reminders list **"Codex Kanban."** These scripts are
the only way anything but a human hand writes to it.

## What AppleScript can and cannot do here

Established by dumping a reminder's properties on 2026-08-27. Reminders exposes:

`name` · `body` · `flagged` · `priority` · `completed` · `container` · `id` · four dates

It does **not** expose **sections** or **tags**. So:

| | who does it |
|---|---|
| Move a card between columns | **Scott, by hand.** Not scriptable at all. |
| Set a tag | **Scott, by hand.** Not scriptable. |
| Rewrite titles and notes in bulk | these scripts |
| Flag a card (= ship-blocker) | these scripts |
| Tick a card off as finished | these scripts |

That division is not a workaround, it is the arrangement: Scott owns the shape
of the board, the scripts own what is printed on the cards.

## The scripts

Run every `dryrun` before its `apply`. The dry runs read only and report what
would change; the applies are idempotent and abort rather than write a partial
plan.

| file | what it does |
|---|---|
| `dryrun.applescript` / `apply.applescript` | stamp `WIRE —` / `DRIFT —` into the notes of the cards that need it, and flag the two ship-blockers |
| `notes_dryrun.applescript` / `notes_apply.applescript` | rewrite **all 91** notes from `notes.tsv` |
| `retier_dryrun.applescript` / `retier_apply.applescript` | change tiers, sizes and notes in bulk, keyed on the card id |
| `probe.applescript` | read-only health check: what AppleScript can see, and which known card has gone missing |
| `probe_subtask.applescript` | the experiment that settled the subtask question; kept as the record |
| `create_glossary_card.applescript` | authors `K-000`, the glossary card. Re-run it to edit the glossary |
| `notes.tsv`, `retier.tsv` | the data: one card per line, tab separated, UTF-8 |

```sh
osascript "/Users/scott/Documents/Code/Codex Reader/scripts/kanban/notes_dryrun.applescript"
osascript "/Users/scott/Documents/Code/Codex Reader/scripts/kanban/notes_apply.applescript"
```

Reminders syncs each write to iCloud, so 91 writes will beachball the app for
minutes. It is safe to interrupt and safe to re-run — a re-run skips every card
already correct.

## Two traps that cost a round each

**Encoding.** The original import scripts are **MacRoman** (`·` is byte `0xE1`),
not UTF-8. Open one in the wrong editor and every separator becomes `á`. These
scripts are therefore **pure ASCII**, and the text with accents in it lives in
`notes.tsv`, read through `do shell script`, which decodes UTF-8 correctly.

**Line endings.** `do shell script` returns **carriage returns**, not linefeeds.
Splitting the data file on `linefeed` alone reads all 91 rows as one line and
yields zero rows — with no error. Both scripts split on `{return, linefeed}`.

## The subtask trap — measured, not guessed

**Dropping one card onto another makes it a subtask, and a subtask is invisible
to AppleScript.** Measured 2026-08-27: the count went 92 → 91 the moment a card
was nested, and `reminders of reminder N` is not in the dictionary at all —
*"Can't get every reminder of reminder 1 of list."* There is no way to reach a
nested card, read it, or even tell that it is nested.

**The fix is not Undo. Select the card in Reminders and use "Outdent Reminder."**

This is a nasty failure because it is silent and easy — a drag that travels a
little too far. The card still looks present to a human; it has simply left the
board as far as every script is concerned, and its note quietly goes stale.

Two defences, both built:

- **`probe.applescript`** compares the board against the id register and names
  any card that has vanished. Run it after any session of heavy rearranging.
- **The bulk scripts refuse to run** if a known card is missing, rather than
  skipping it. They say which id, and they say to outdent.

## Card ids, and why the scripts key on them

Scott re-tiers cards by retyping the title. A title-keyed script therefore
breaks the moment he touches his own board, which is backwards. Every script
here finds a card by the `K-0NN` id at the start of its note, so titles are safe
to edit — and safe to fat-finger. `K-000` is the glossary card and is skipped by
the bulk scripts; `K-???` is what a new card written by hand should carry until
an id is assigned.

## Note length — 250 characters, and Reminders will not tell you

**Reminders truncates a long note on the card face with no ellipsis.** An
overflowing note looks like a complete sentence that simply stops. Measured
2026-08-27 against a full-board screenshot: **249 characters displayed in full,
263 was cut** — K-006 ended on the words *"Built, and"* and read as finished.

Scott cannot detect this by looking; the tooling has to. So:

- **Keep every note at or under 250 characters.** `probe.applescript` reports
  any that exceed it, by id and length.
- **If one genuinely must run long, end the visible part with `[more...]`** so
  the card admits it is truncated instead of appearing to stop mid-thought.
- **Anything that needs real length does not belong on a card.** It belongs in
  the directive, in `KANBAN_IDS.md`, or on the glossary page.

That last rule is why `K-000` is only a pointer. A full glossary in a note is
unreadable at any length Reminders will show.
