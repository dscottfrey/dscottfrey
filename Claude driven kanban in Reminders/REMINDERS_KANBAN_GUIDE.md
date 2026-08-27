# Running a kanban board in Apple Reminders, driven by AppleScript

**A portable write-up.** Nothing here is specific to the project it was written
in — lift the whole file. Everything in it was measured on macOS in August 2026,
not taken from documentation, because the documentation does not cover most of it.

The short version: Reminders makes a genuinely good kanban board for one person
plus a collaborator, and AppleScript can maintain the *contents* of the cards but
**not their arrangement**. That single constraint determines the whole design, so
it comes first.

---

## 1. What AppleScript can and cannot touch

Find this out for yourself before designing anything, by dumping one card:

```sh
osascript -e 'tell application "Reminders"' \
          -e 'activate' \
          -e 'get properties of first reminder of list "MY BOARD"' \
          -e 'end tell'
```

The complete property list, as of this writing:

```
name · body · flagged · priority · completed · container · id
allday due date · due date · remind me date · completion date
creation date · modification date
```

Note what is **absent**: no `section`, no `tag`, no `url`, no parent or subtask
relationship. The Reminders *app* has all four of those in its UI. AppleScript
does not.

| | who can do it |
|---|---|
| Move a card between columns (sections) | **a human, by hand, only** |
| Add or read a tag | **a human, by hand, only** |
| Create, rename, retitle a card | script |
| Rewrite the note | script |
| Set the flag | script |
| Set priority (none / low / medium / high) | script |
| Tick a card off as complete | script |
| Read any of the above | script |

> If Reminders is not already running you get `-600 Application isn't running`.
> Add `activate`, or just leave the app open.

### What this means

**You cannot script the board's shape.** No moving cards between columns, ever.
Plan for a human to do that, and design so it is a pleasant batch job rather than
a chore — see §6.

**You get exactly three machine-writable state bits beyond the text:** `flagged`,
`priority`, and `completed`. Spend them deliberately. A workable assignment:

- `flagged` = **blocker**. Reminders has a built-in Flagged smart list, so this
  gives you a permanent cross-list view of everything urgent for free.
- `completed` = **finished**. Completed cards sort to the bottom struck through,
  which doubles as the "these need filing into Done" worklist.
- `priority` = leave it free until you have a question that needs it. It renders
  as `!`/`!!`/`!!!` and reads as urgency, so do not press it into other service.

Everything else — the kind of work, the size, the release, an id — has to be
**printed in the title or the note**.

---

## 2. The card format

Two lines carrying five facts:

```
title:  v1.0 · shelf · Bulk select
note:   K-027 · Medium — You cannot select several books at once, so deleting
        or sharing more than one means doing it one at a time. §9.1
```

| part | where | why there |
|---|---|---|
| **tier** (`v1.0`) | title, first | sorting a column by title groups by tier for free |
| **module** (`shelf`) | title, second | ties a card back to its spec |
| **id** (`K-027`) | note, first | the stable handle; see §3 |
| **size** (`Medium`) | note | relative, never in hours |
| **the point** | note | what a person would *notice*, and why it matters |
| **pointer** (`§9.1`) | note, last | for whoever implements it |

Two rules that matter more than they look:

**Write the note for the person who cannot read the code.** If a note says
`AnnotationExporter exists; §5.3 never built`, only an implementer can act on it.
`There is no way to get your highlights out of a book. The exporter is built; it
has no button anywhere.` can be prioritised by anyone. A board nobody can read is
a board nobody can rule on.

**A note that misleads about effort is as broken as one full of class names.**
"The whole client is built" read as "nearly done" when it meant "the engine
exists and the entire UI does not."

---

## 3. Key on an id, never on the title

The obvious design is to match cards by title. It is wrong, and it fails on the
first day.

**People re-tier by retyping the title.** So a title-keyed script breaks the
moment the human touches their own board — backwards, since the board is theirs.
A single stray keystroke turning `v1.1` into `v1.01` aborted a run here.

So: **give every card a permanent short id and put it first in the note.** Match
on that. Then titles are free to be edited, mistyped, and reworded, and the
tooling never notices.

- Format `K-001`, three digits zero-padded. Prefer decimal over hex — these get
  spoken and retyped, and `K-0B8` versus `K-088` is a transcription error waiting
  to happen. If you ever pass 999, add a letter *then*; nothing computes on it.
- **Never reuse an id**, including for finished or deleted work, so an old
  reference always resolves.
- Reserve `K-000` for a glossary card (§7).
- For a card a human adds by hand: have them start the note with `K-???`. It is
  explicit, so it can only mean "needs an id" — whereas a card with *no* id is
  ambiguous between that and a card the tooling failed to write.
- Keep the id ↔ card register in a file under version control, so it survives
  without querying the board.

---

## 4. Standing up a board

AppleScript cannot create sections, so setup is a dance:

1. **Batch-create every card with its state as a title prefix** — `TODO · `,
   `WIRE · `, `DONE · `, etc. Split into a few scripts by state; it makes the
   next step easier.
2. **Sort the list by title.** Cards clump by state.
3. **Create the sections by hand and drag each clump in.** Tedious once, never
   again.
4. **Run a script that strips the prefixes back off**, now that the column
   carries that meaning.

```applescript
-- Batch create. One script per state reads best.
tell application "Reminders"
	activate
	if not (exists list "MY BOARD") then make new list with properties {name:"MY BOARD"}
	tell list "MY BOARD"
		make new reminder with properties {name:"TODO - v1.0 - shelf - Bulk select", body:"K-027 - Medium - ..."}
		-- ...
	end tell
end tell
```

```applescript
-- Strip the prefixes after sectioning. Safe to run twice.
set statusWords to {"TODO - ", "WIRE - ", "DONE - "}
tell application "Reminders"
	tell list "MY BOARD"
		repeat with r in reminders
			set t to name of r
			repeat with w in statusWords
				set wLen to length of (w as text)
				if length of t > wLen and text 1 thru wLen of t is (w as text) then
					set name of r to text (wLen + 1) thru -1 of t
					exit repeat
				end if
			end repeat
		end repeat
	end tell
end tell
```

---

## 5. Five traps, each of which costs a debugging round

### 5.1 Encoding — write pure ASCII, keep the text in a data file

`.applescript` files are historically **MacRoman**, not UTF-8. A middle dot `·`
is byte `0xE1`. Open one in a UTF-8 editor and every separator becomes `á`.

Do not fight this. Instead:

- Keep the **script source pure ASCII**. Build any needed character with
  `character id 183` (`·`), `character id 8212` (`—`).
- Keep the **text with accents in a separate UTF-8 data file** (TSV works), and
  read it with `do shell script "cat …"`, which decodes UTF-8 correctly.
- Verify before running: `LC_ALL=C grep -n '[^ -~\t]' script.applescript` should
  print nothing.

### 5.2 `do shell script` returns CARRIAGE RETURNS

Splitting the data file on `linefeed` alone reads the entire file as **one line**
and silently yields **zero rows** — no error, no warning, and a report that
everything matched nothing. Always:

```applescript
set AppleScript's text item delimiters to {return, linefeed}
```

### 5.3 A subtask is invisible — and it is one bad drag away

**Dropping one card onto another makes it a subtask, and a subtask cannot be
reached from AppleScript at all.** Measured: the list count went 92 → 91 the
instant a card was nested, and `reminders of reminder N` is not in the dictionary
— *"Can't get every reminder of reminder 1 of list."* You cannot read it, write
it, or detect that it is nested.

This is the worst failure here because it is **silent and easy**: a drag that
travels slightly too far. The card still looks present to the human; it has left
the board entirely as far as every script is concerned, and its note quietly
rots.

**The fix is not Undo. Select the card and use "Outdent Reminder."**

Two defences, and you want both:

- A **probe** that compares the board against your id register and *names* what
  is missing (§6).
- Bulk scripts that **abort** when a known id is absent, rather than skipping it.

### 5.4 Notes truncate at ~250 characters with no ellipsis

An overflowing note reads as a sentence that simply stops. Measured: **249
characters displayed in full, 263 was cut** — a note ending on the words
*"Built, and"* looked finished.

The human cannot detect this by looking, so the tooling must:

- Cap notes at **250 characters** and have the probe report any that exceed it.
- If one genuinely must run long, end the visible part with **`[more...]`** so
  the card admits it is truncated.
- Better: anything needing real length does not belong on a card. Put it in a
  document and link to it.

### 5.5 Writing by index is unsafe if the list changes mid-run

Scripts naturally read a snapshot, compute a plan, then write with
`set body of reminder 7`. If a card is **added or deleted** during the run, every
index after it shifts and writes land on the wrong cards. Dragging between
columns is safe; adding and deleting are not.

Either re-find each card by id at write time, or adopt a procedure: press Escape
so nothing is in edit mode, switch away from Reminders — **do not quit it** — and
do not touch the board until the prompt returns.

Every write also triggers an iCloud sync, so ~90 writes is minutes of beachball.
Make scripts **idempotent** (compare before writing, skip what already matches)
so an interrupted run is resumed by simply running it again.

---

## 6. The script set worth having

Four, and the discipline of always running the dry run first.

**`probe.applescript`** — read-only health check. Reports how many cards
AppleScript can see, how many carry an id, which known ids are **missing**
(§5.3), and which notes exceed the cap (§5.4). Run it after any session of heavy
rearranging.

**`<job>_dryrun.applescript` / `<job>_apply.applescript`** — generate the pair
from one source with a `DRY_RUN` flag so they cannot drift apart:

```sh
sed 's/^set DRY_RUN to true$/set DRY_RUN to false/' job_dryrun.applescript > job_apply.applescript
```

The apply must **resolve the entire plan before writing anything** and refuse
outright on any unresolved card, so it can never apply half a plan.

**Check matching in both directions.** Every card must find a data row *and*
every data row must find a card. Checking only the first direction means a hidden
card is silently skipped rather than reported — exactly the §5.3 failure.

**`create_glossary_card.applescript`** — see §7. Idempotent: if the card exists,
refresh it rather than creating a second. Editing the glossary then means editing
the script and re-running it.

### The batch delta

Because a human moves the cards, do not expect them to do it as work happens.
Nobody moves a card mid-build. Instead, at the end of a working session, hand
them a **delta**: which cards move, and to which column. Better still, use
`completed` — ticked cards sink to the bottom struck through, and *that* is the
delta, sitting on the board where they are already working.

One rule worth agreeing explicitly if an assistant is doing the ticking: **tick a
card off only when the work has been confirmed by the human on real hardware,
never on having written the code.** "Done" from source alone is a claim about
code, not about the product.

---

## 7. The glossary card

Reserve `K-000` for a card that explains the board. A collaborator should not
have to reverse-engineer what your "Wire" column means.

But **keep it a pointer, not the glossary**. A real glossary does not fit in 250
characters and Reminders will truncate it without saying so. Put the three or
four definitions worth having unprompted on the card, plus a link to the full
version, and host the real thing as a web page or a document.

Have the bulk scripts recognise `K-000` and **skip it** — its text is authored
once by hand, and it may contain newlines that a TSV data file cannot carry.

---

## 8. Whether to build a bridge app instead

EventKit gives you `EKReminder` with title, notes, priority, completion, dates
and list. It **probably does not expose sections or tags either** — those look to
live in the app's own store with no public API. Verify before you spend a
weekend; the answer moves with OS releases.

What an app would genuinely buy: stable identifiers instead of positions (killing
§5.5 outright), writes that do not route through the UI (no beachball), and no
permission prompt per script. Speed and safety, not new powers. The
human-moves-the-columns arrangement survives it.

---

## 9. The short checklist

- [ ] Dump a card's properties first. Do not trust anything above without checking it on your OS.
- [ ] Permanent id at the start of every note. Key everything on it.
- [ ] Script source pure ASCII; accented text in a UTF-8 data file.
- [ ] Split on `{return, linefeed}`, never `linefeed` alone.
- [ ] Notes capped at 250 characters.
- [ ] Dry run before every apply. Both directions checked. Abort, never partially apply.
- [ ] A probe that names missing cards, because a subtask vanishes silently.
- [ ] Idempotent writes, so an interrupted run resumes by re-running.
- [ ] Agree who owns the columns. It is not the script.
