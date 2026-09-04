# 01 — Planning Workflow

How to set up the planning and build system and run it session by session.

**Revised 2026-09-04** from four months of the Codex project. The original version of this file described a two-workspace system (a Cowork planning folder plus an Xcode build folder, with `Docs/` copied between them). Codex abandoned that within weeks. What it settled into is described first; the two-workspace model is kept at the end as the historical alternative, with the reason it lost.

**Revised 2026-09-04, Icarus.** A second project, run in parallel by the same owner, reached the same shape independently — one repo, no sync step — and then diverged from Codex in how it holds state (no board, dated handoff files, a start-here file that grew instead of being rewritten). Those variants are recorded in place, with what each cost.

---

## The Core Idea: Plan Before You Build

The most expensive mistake in AI-assisted development is handing Claude Code a vague goal and letting it fill in the design. You get code quickly, but it reflects Claude's assumptions — not yours. The planning layer exists to capture your decisions before any code is written, so Claude Code is executing a spec, not inventing one.

**The rule:** Nothing gets built until it is specified in a directive. If a decision is not in a directive, it has not been made.

That rule survived Codex intact. What changed is *where* the planning happens.

---

## One Repo, One Terminal

Planning and building happen in the **same repository, in the same terminal sessions**. There is no separate planning workspace and no sync step.

```
<project>/
├── CLAUDE.md                  ← rules of engagement; read automatically every session
├── Docs/
│   ├── RESUME.md              ← START HERE. Rewritten, dated, what to do next
│   ├── HANDOFF.md             ← append-only ledger of WHY. Never read end to end
│   ├── 00_OVERALL_DIRECTIVE.md
│   ├── 01_[MODULE].md …       ← the directives; the spec
│   ├── OWED.md                ← harvested from `// OWED:` comments; what looks finished and is not
│   ├── KANBAN_IDS.md          ← register of board cards (see "The Board")
│   ├── KANBAN_GLOSSARY.md     ← the board's vocabulary
│   └── skills/<name>/         ← master copies of project skills
├── .claude/
│   ├── memory/                ← the assistant's memory, IN the repo (see below)
│   └── skills/<name> → ../../Docs/skills/<name>   (symlink)
└── scripts/
    ├── link-claude-memory.sh  ← run once per machine after cloning
    ├── harvest_owed.py        ← regenerates Docs/OWED.md
    └── kanban/                ← board scripts; dry run before apply, always
```

**Why one repo won.** Three reasons, all learned the hard way:

1. **The sync step was the failure point.** Every planning session ended with "copy `Docs/` to the project root." Miss it once and Claude Code builds to last week's spec. A step that must be remembered is a step that will be skipped — the same reasoning the kit already applies to build numbers.
2. **Decisions are made mid-build anyway.** The real rulings on Codex happened while a build was being tested — "the left leaf is always odd", "typography is per device" — in the terminal, with the code open. A separate planning workspace would have been empty the day the decision was made.
3. **Two machines, one owner.** Codex is directed from a desktop and a laptop. With everything in the repo — directives, memory, skills, board register — `git push` on one machine is the whole hand-off to the other.

Cowork remains useful for reading and discussing long documents. It is not where the spec lives.

---

## The Three Tiers of Project State

Codex ended up with three places holding three different kinds of state. They are **not interchangeable**, and reading the wrong one wastes an evening.

| Tier | Lives in | Holds | How it is written |
|---|---|---|---|
| **RESUME** | `Docs/RESUME.md` | What to do next, and the habits that matter. The ten-minute version. | **Rewritten.** Dated sections (`§4.17 — 2026-09-03, EVENING. START HERE.`), newest marked, older sections kept below and demoted as they age. |
| **HANDOFF** | `Docs/HANDOFF.md` | **Why.** Every decision, finding, dead end and reversal, dated and numbered (`§13.95`, `§24.3`). | **Append-only.** On Codex it passed 8,000 lines. Nobody reads it end to end; it is grepped and cited by section number. |
| **The board** | Outside the repo (on Codex: an Apple Reminders list) | **State.** What is backlog, deferred, built-but-unreachable, done. | By the owner's hand, swept in batches after the fact. |

The sentence that keeps them straight: **the board holds state, HANDOFF holds why, RESUME says what to do next. Do not ask the board what is happening right now** — it is swept in batches, after the work, and it lags.

### RESUME — the start-here file

Born on Codex because HANDOFF had become unreadable. A pointer in memory ("see HANDOFF §13.84") went stale for weeks before anyone noticed. RESUME is short enough to keep current and is **rewritten**, not appended — the newest section says START HERE, states the build in the tree, the single next step, what is known-broken and deliberately untouched, and what is owed. See `TEMPLATES/RESUME.md`.

Its first section on Codex is not status at all. It is the habit that mattered most — see "Check Whether It Exists" below.

**Where the rewrite rule failed *(Revised 2026-09-04, Icarus)*.** Icarus has the same file (`RESUME_HERE.md`, at the repo root) and never rewrote it: every session *prepended* a block. By September it was 1,374 lines and 104 KB, with a banner at the top — *"Top block updated 2026-08-28. Everything from 'FRESH START 2026-07-13' down is older"* — which is the rewrite rule being replaced by a warning that it was not followed. It still works, because the top block is honest and dated, but the file is now the size the HANDOFF was on Codex when RESUME was invented. The cause is ordinary: prepending is cheaper at the end of a tired session than deciding what to demote. If a project cannot hold the rewrite discipline, the fallback that kept Icarus usable is (1) a dated "top block updated" banner so the reader knows where current ends, and (2) the older blocks kept below *because rulings in them are still cited by date*. What the top block on Icarus holds, and the template now asks for: the unbuilt work with its build-and-test steps, the decisions the owner owes (numbered, with a recommendation each), and the open items found but deliberately not fixed.

**Two dated blocks Icarus added that the template lacked:** a **"decisions owed by the owner"** block — numbered questions, each with the assistant's recommendation and the reason, written because the owner asked for them to be *there* rather than re-derived in chat — and a **"reminded on resume"** item, which is a memory that says *raise this unprompted at the start of the next session*, deleted once the owner confirms it done.

### HANDOFF — the ledger

Keeps the original kit role: decisions, rationale, what was rejected. What Codex added is **numbered, dated sections that are cited like law**. A card's note says `HANDOFF §13.59`; a memory says `§13.95`; a comment in the code says `see HANDOFF §22.6`. The number is the address. Never renumber.

A HANDOFF entry that only ever lives in HANDOFF is itself a complaint: a decision with no home in a directive. The glossary on Codex says so in as many words.

**The Icarus variant — one file per session day *(Revised 2026-09-04, Icarus)*.** Instead of one append-only ledger, Icarus writes `Docs/HANDOFF_<date>[_<topic>].md` — nine of them in four months, 100–475 lines each — and cites them by filename and section heading rather than by number. The shape that recurs in every one and is worth copying: **the decision that matters, first, with "do not undo this without reading the whole section"**; then *open* threads; then **"Owner decisions this session — do not re-litigate"**; then **"Not a bug — recorded so nobody 'fixes' it"** (a deliberate behaviour that looks wrong, with the reason it is right — on 2026-07-29 this included a recommendation the assistant itself had made and been wrong about); then **"Not yet proven on a real run"** (what shipped compile-verified only); then **"No schema change"** or what changed; then a process note. Alongside sit `Docs/Reports/` (analyses of real runs, written for the customer — see `07`), `Docs/Migrations/v<N>.md` (one per schema bump), `Docs/RELEASE_NOTES.md` (the lab-facing running record, see `TEMPLATES/RELEASE_NOTES.md`) and `Docs/Deployment/` (the ship order and host-machine notes). Either shape works; what matters is that a session's *why* is dated, findable, and never edited into silence.

**The board.** Icarus has none. With one operator, one customer and no testers, RESUME's top block plus the memory files carried state well enough that a board was never wanted. The tier is optional; the sentence that keeps the tiers straight still applies to the two that exist.

### The board — state outside the repo

Codex uses an Apple Reminders list. The points that generalise to any board:

- **Every card has a permanent id** (`K-001` …), registered in `Docs/KANBAN_IDS.md` with a plain-English line saying what it means, plus a reverse index from directive section to cards. **Refer to work by its id.** Ids are never reused.
- **The vocabulary is written down** (`Docs/KANBAN_GLOSSARY.md`): the columns and what each *means*, the tiers, the module tags, and what a card's note may contain (a pointer — `§8.4`, `Backlog 3`, `OWED O0` — never instructions).
- **The owner owns the shape; scripts own the print.** On Codex, AppleScript cannot see sections or tags, so columns are moved by the owner's hand only. Titles, notes and the checkbox are scriptable — and the scripts are run only after a ruling, with a dry run first, because a status that lives in two places (a checkbox and a column) can only be half-corrected by a script. A batch of fifteen "corrections" once left the board unusable.
- **Never predict what the owner sees on the board.** What a script returns looks nothing like the owner's screen. Ask for a screenshot.
- **The checkbox rule.** A card is ticked only after the owner has confirmed the work on a device — never on having written the code. `WRITTEN <date>` and `DONE <date>` are different words and the note must use the right one.
- **A value outside the known set is deliberate.** The owner once tiered a card `v1.5` on a board with no such tier, precisely because no such tier existed. Do not normalise it; ask.

The board is the owner's instrument for holding the work in their head. Anything that makes it wrong in the owner's view is a net loss even when it is right in the data.

---

## The Assistant's Memory Lives in the Repo

Claude Code keeps per-project memory at `~/.claude/projects/<encoded-path>/memory/`, which is machine-local by default. On a project directed from two machines that means facts learned on one never reach the other.

Codex symlinks that directory to `.claude/memory/` **inside the repo**, so memory travels with `git push` like everything else. The script is `TEMPLATES/link-claude-memory.sh`; copy it to `scripts/` and run it once per machine after cloning. It backs up any real directory it finds and replaces an existing symlink, so re-running is safe.

Put the instruction in the build `CLAUDE.md`: *if the memory directory is empty or missing, run the script first.*

What this buys: the assistant's own hard-won rules — "instrument before theorising", "never delete by a computed address", "one build in flight at a time" — are in version control, reviewable by the owner, and identical on both machines.

**Icarus did not do this *(Revised 2026-09-04, Icarus)*.** Its forty memory files live in the machine-local directory only, although the project is directed from the same two machines. Whether that cost anything is not recorded — no session on Icarus noted a fact missing on the other machine — so this is an open question for the kit, not a finding. What Icarus *did* do that generalises: memory files there carry **"Why"** and **"How to apply"** paragraphs and link each other by name, and several are written as **standing instructions to a future session** ("say COMMIT FIRST unprompted", "raise this on resume"), which is the form that turned out to change behaviour. A memory that only records a fact is read; a memory that says what to *do* with it is obeyed.

---

## Skills — Where Hard-Won Rules About a Dependency Live

A dependency that took weeks to learn (on Codex, the Readium toolkit) needs more than a directive section. The rules — what was tried, what broke, what must never be done again — go in a **project skill**, loaded before any code that touches the dependency.

- The master copy is at `Docs/skills/<name>/SKILL.md`, writable and git-tracked.
- `.claude/skills/<name>` is a **symlink** to it. One file, no copy step, no drift. (Codex briefly documented a copy step that did not exist; a session spent time looking for it.)
- Keep the master current as the code changes, unprompted.
- When an installed expert skill and a research pass conflict on a technical claim, **follow the skill and say what was dropped**. The one exception is research that is merely transcribing a primary source (the vendor's engineers, docs, DTS) — that is skill-versus-vendor and worth a sentence to the owner first.

---

## Directive Files

Unchanged from the original kit. Each major module gets its own directive in `Docs/`, numbered for reading order, with `00_OVERALL_DIRECTIVE.md` the document every other defers to. See `04_DIRECTIVE_WRITING.md` and `TEMPLATES/MODULE_DIRECTIVE.md`.

The addendum pattern also stands: features planned on an experimental branch go in `NN.1_MODULE_ADDENDUM.md`, not the main directive, so the main directive can be recertified if the branch dies. See `TEMPLATES/ADDENDUM.md`.

---

## Session Start Ritual

Every session, in this order:

1. `CLAUDE.md` (read automatically).
2. **`Docs/RESUME.md`** — the newest section marked START HERE. This is the only file that is guaranteed current.
3. `Docs/HANDOFF.md` — only the sections RESUME points at. Never the whole file.
4. The directive for the module being worked on.
5. The project skill, if the work touches the dependency it covers.
6. Summarise: what the project is, the build in the tree, what today's work is, and any open question in the directive that blocks it. **Then wait.**

`prompt.txt` says exactly this and is the opening message of every build session.

### Check Whether It Exists — the habit that matters most

On one day of the Codex project, twenty-one cards were closed and **nine of them needed no building**: the feature was already built (sometimes with zero callers), already ruled in a backlog file, or already answered in a directive section written a fortnight earlier. The owner's words: *"I want to stop reinventing things we have already decided upon."*

So, before writing a line, in order:

1. **Grep for the type or the phrase.** Seconds. Twice in one day this found a complete, working implementation.
2. **Read the directive, not the card.** Board notes are summaries and go stale. The directive, the backlog file and `OWED.md` are the source.
3. **Check for zero callers.** *Built and unreachable* is the commonest state on a mature AI-assisted codebase, not *unbuilt*. Grep the type name outside its own file; if nothing comes back, the feature exists and has no door.
4. **Check even when the owner says it does not exist.** The owner said *"I don't think there is code"* about sharing. There was, and it had shipped the day before. The app is large and the record is chronological; the owner's recollection is not the source of truth and neither is the assistant's.

---

## Session End Ritual

1. **RESUME gets a new dated section** at the top: the build in the tree (stamp and commit), the single next step, what is known-broken, what is owed. Old sections stay below.
2. **HANDOFF gets the why**: every decision made, every finding, every dead end, as a new numbered section. Reversals are recorded as reversals, never by editing the original.
3. **The directive is updated** for any ruling that belongs in the spec — the moment it is made, not at session end. See `04_DIRECTIVE_WRITING.md`.
4. **The code exports its memory.** Anything deliberately left unfinished carries `// OWED:` (what a *reader* would notice, written for the owner), optionally `// WHY:` and `// TRIGGER:`. Run `scripts/harvest_owed.py` to regenerate `Docs/OWED.md`. The reason: on a project directed by a non-developer, a decision recorded only in a comment is invisible to the person directing the project. Bare `TODO`s are reported by the harvester as invisible.
5. **The board delta** is handed to the owner as text — exact card titles, the column to move each to, new cards pre-written in the board's vocabulary. The owner sweeps the board in batches, afterwards.
6. Commit. (On Codex the assistant commits locally and never pushes; pushing is the owner's.)
7. **Say where the shipped source lives *(Revised 2026-09-04, Icarus)*.** Icarus shipped 1.1.0, 1.2.0, 1.3.0, 1.3.1 and 1.3.2 to the lab from a fix branch that had **no upstream** — 37 commits ahead of `main`, existing on one machine only, for a month. Every handoff in that month opened with the warning in bold, which is the right thing to do and is not the same as the branch being pushed. A shipped build's source must exist in more than one place; until it does, the handoff says so at the top, every time.
8. **List what shipped unproven.** Alongside known-broken: the changes that compiled but were never run before the build went out (Icarus, 2026-07-30: five of them, one of which could silently drop every data row if its column count disagreed with the header). The list tells the next session what a short run must exercise first.

---

## When Claude Code Goes Wrong

When Claude Code implements something differently than the directive specifies:

1. Identify the specific gap between what was built and what the directive says.
2. Update the directive to be more explicit about the requirement (if it was ambiguous).
3. Give Claude Code a correction message that references the directive section by number.

The directive is the source of truth. If Claude Code did something different, either the directive was ambiguous (fix the directive) or Claude Code made an error (correct it with a reference to the directive). Either way, the directive wins.

---

## What Stays in Conversation vs What Goes in the Directive

**Conversation:** exploration, questions, options being weighed, things not yet decided.

**Directive:** every decision, immediately after it is made.

The moment a decision is made in conversation, update the directive. Conversations are not searchable, not persistent across sessions, and not visible to the next session.

**The corollary Codex added: discussion is not instruction.** An owner who thinks out loud — "it feels like a v1.0", "to be fair, that is how they access the library now" — has not issued a ruling. Answer with reasoning and record the finding in HANDOFF; change no tier, scope or priority the owner did not ask to move. A ruling sounds like one. When it could be either, ask in one line.

---

## Unattended Runs

The original kit described running Claude Code unattended with `--dangerously-skip-permissions` behind an allow/deny list. **Codex never used it.** Every session is interactive; the owner reads and approves each prompt, and the settings and directives files (`~/.claude/CLAUDE.md`, `settings.json`) are deny-listed so the assistant cannot rewrite its own rules or permissions even by an accidental "always allow". The deny-list is the standing safeguard; the unattended mode is not recommended on the strength of Codex's experience and is kept here only so the option is not rediscovered.

---

## The Two-Workspace System (historical)

The original model, kept for projects that want a separate planning environment. See `TEMPLATES/CLAUDE_PLANNING.md`.

**Layer 1 — Planning workspace (Cowork):** `CLAUDE.md`, `Docs/`, notes and addenda. No code. **Layer 2 — Build workspace (Xcode + Claude Code):** its own `CLAUDE.md`, an exact copy of `Docs/`, all source. Layer 1 is the source of truth; Layer 2 is synced from it at the end of every planning session where a directive changed.

Why Codex dropped it is stated above: the sync step was the failure point, decisions were made mid-build anyway, and one repo across two machines was simpler. If a future project keeps two layers, the sync step must be mechanical — a script, not a reminder.

**A second data point *(Revised 2026-09-04, Icarus)*.** Icarus was seeded this way too — its directives were drafted in Cowork and placed at the project root — and abandoned the copy step just as fast. Four months on, its overall directive still says *"`Docs/` is copied wholesale from the planning workspace before any build session"*, a sentence no session has performed since May. Two projects, same outcome: the model is historical.
