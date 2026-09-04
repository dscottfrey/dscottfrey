# RESUME — start here

**Written [date].** [One or two sentences: the day's real finding, the thing that
shapes everything below. On Codex the first version opened with "nine of
twenty-one cards closed today were already built, already ruled, or already
answered" — a habit, not a status.]

`Docs/HANDOFF.md` §[N.N]–§[N.N] is the full ledger. This is the ten-minute
version.

---

## 1. THE ONE HABIT THAT MATTERS

**Before building anything, check whether it exists.** Grep the type or the
phrase; read the directive, not the card; check for zero callers; check even
when the owner says it does not exist.

Three registers exist and reading the wrong one wastes an evening:

- **`Docs/KANBAN_IDS.md`** — every card, its id, what it means. State is on the board.
- **`Docs/OWED.md`** — what the code has started and not finished. Regenerated, never hand-edited.
- **`Docs/HANDOFF.md`** — why decisions were taken. The dated ledger.

---

## 2. The board

**Live in [where — e.g. Apple Reminders, list "<Project> Kanban"].** Any snapshot
in the repo is frozen and must not be read as current.

- **The owner owns the columns and the tiers.** Moved by hand, only.
- **Scripts own what is printed on the cards** — `scripts/kanban/`. Dry run before apply, always.
- **`v1.0` = [the bar, in one sentence — a capability someone else has to clear, not a date].**
- **There is no ship date.** [Or: the ship date is X, and what that changes.]

---

## 3. What is in flight

**[Nothing is half-finished / X is half-finished, here is its state.]**

**Build in the tree:** `[stamp]` (commit `[hash]`), [handed to the owner / not yet built / on TestFlight as `[build number]`].

**Test round open?** [Yes — on which device, testing what; the tree is frozen for that path. / No.]

**Shipped source in one place?** [No. / YES — branch `<name>` has no upstream, N commits ahead of `main`, exists only on `<machine>`; builds `<versions>` shipped from it. Say this here until it is pushed. *(Revised 2026-09-04, Icarus.)*]

**Shipped but never run:** [the changes in the last handed build that compiled and were not executed before it went out, riskiest first, and the one short run that would exercise them. *(Revised 2026-09-04, Icarus.)*]

---

## 3a. Decisions owed by the owner *(Revised 2026-09-04, Icarus)*

[Only when there are any. Numbered. Each: the question in one line, the assistant's
recommendation, the reason, and what is ready to build the moment it is answered.
Written here because the owner asked for them to be *here*, not re-derived in chat.
On Icarus the block also states *why the question is open at all* when the hardware
or the premise moved under an earlier ruling — "not re-litigating a settled question."]

## 3b. Remind on resume *(Revised 2026-09-04, Icarus)*

[Anything the owner asked to be reminded of unprompted at the start of the next
session — with the steps in order (commit first; build; the regression test; the
path it may have broken). Delete the item when the owner confirms it done.]

---

## 4. Dated sections — newest first

### 4.N — [date], [MORNING/AFTERNOON/EVENING]. **START HERE.** [One-line headline.]

[What was built and device-confirmed. What is owed first tomorrow. What is
known-broken and deliberately untouched. Which HANDOFF section is the day.]

**Owed first tomorrow:** [the single next step, in one sentence].

**Known-broken, do not report:** [list, kept current — an item stays only while it is actually unbuilt].

### 4.N-1 — [date]. [Headline.] — superseded by §4.N, kept for its rulings.

[Older sections stay. Demote them in the heading, never delete them; a ruling
made that day is still cited by this section number.]

[If the rewrite discipline slips and this file is only ever prepended — it did on
Icarus, to 1,374 lines — put a dated banner at the very top: "Top block updated
<date>. Everything from <heading> down is older." The reader must always know where
current ends. *(Revised 2026-09-04, Icarus.)*]

---

## 5. The working method — the rules that must not be relearned

[Five to ten one-line rules with the memory or HANDOFF section that holds each.
On Codex: one build in flight at a time; the stamp and the log are the
assistant's to check; say what is known-broken before the owner tests;
instrument before theorising; ask for a picture; never delete by a computed
address.]
