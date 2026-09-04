# 02 — Development Philosophy

Principles that apply to every line of code in every project. These are not aspirational — they are requirements. Put them in your build `CLAUDE.md` and in your overall directive. They apply to every session, every module, every commit.

**Revised 2026-09-04** from the Codex project's first four months of real use — a dozen TestFlight testers, three devices, and several hundred build-and-report rounds. Sections marked *(learned on Codex)* were added or rewritten from that experience; the worked examples name the day each lesson was paid for. Nothing from the 2026-05-04 version was removed.

**Revised 2026-09-04, Icarus** — in parallel, from the Icarus project (2026-05-19 → 2026-09): a macOS lab instrument that measures projector-lamp degradation over 90-day runs for a single customer, directed by the same non-developer owner. Icarus is a different shape of app from Codex — one user, no store, no testers, but real scientific data and a rig nobody watches at 3 a.m. — so it paid for a different set of rules. Sections marked *(learned on Icarus)* are new or refined from it; where Icarus overrode a kit rule on purpose, the override and its reason are recorded in the section, not left silent.

---

## Quantitative Integrity Outranks Convenience *(learned on Icarus)*

**Revised 2026-09-04, Icarus.** This section sits *above* Occam's Razor on purpose. The two pull against each other: "the simplest thing that works" is exactly what writes `?? 0.0` for a missing reading and `cycles × interval` for elapsed time. Both are simple, both work on the happy path, and both put a wrong number in front of someone who will believe it. On Icarus the owner mirrored this rule into the project `CLAUDE.md` above Occam's Razor for that reason: *the order says which wins.*

**The rule:** every number the app shows, records, or sends is accurate to the precision the spec states, or it is not presented at all. An approximate number is worse than none, because it will be believed. The owner, 2026-07-29: *"This is a science lab. Everything must be accurate to within the precision we specify. An elapsed time reading that is approximate or flat out wrong is unacceptable."*

This applies to any app whose numbers someone acts on — a lab instrument, a ledger, a timer, a dashboard — not only to science. Six rules, all testable:

1. **One quantity, one definition.** If two places compute it, they compute it identically from the same source. One word with two meanings — one driving behaviour, one driving the display — is a defect even when both are individually defensible.
2. **A count is not a measurement.** Never substitute a proxy for the thing because the two agree under ideal conditions. Cycles × interval is not elapsed time. Rows written is not data captured. Mains power is not "the lamps are lit". If a proxy is wanted, label it as the proxy it is.
3. **Never fabricate a value for a reading that was not taken.** Missing means an empty cell. Never `0`, never last-known, never interpolated. Where zero is a legitimate reading (lux on a black screen, a temperature), a zero placeholder is indistinguishable from data. This applies identically to files, the database, charts and exports — and it is the mirror image of "Never Silently Lose the User's Content" below: never lose, never invent.
4. **Derived values inherit their source's honesty.** Remaining time, countdowns, alarm thresholds, chart axes and averages read from the accurate source, never from whatever a neighbouring view happens to display.
5. **Measure against an absolute reference; never accumulate increments.** Anything that can drift is computed from a fixed origin, not by adding a step each time round a loop. Accumulated error is silent and grows for as long as the process runs — on Icarus, up to 90 days.
6. **State the precision and honour it.** A displayed precision the value cannot support is a false claim. So is a *label* the number cannot support: a quantity called "Remaining" in time units will be read as "when will this finish", and if it is really "work left priced at the configured rate" the label lies even when the arithmetic is right.

**The acceptance test:** every number the operator can see or receive must be reproducible by hand from the data files. If it cannot be re-derived, it is not trustworthy and does not ship.

### The incident of record — the first real run, 2026-07-23 to 2026-07-28

Icarus's first real five-day run. `EXPERIMENT_ELAPSED_S`, the on-screen Elapsed readout and the chart's time axis were all *cycles completed × reporting interval*, while the stop decision used real time. Cycles averaged 60.9 s against a 60 s interval, so the two diverged by **1 h 44 m over five days**. Three consequences, one per rule:

- the recorded runtime under-reported real lamp hours (rules 1, 2, 5);
- the "time to ending" reminders measured remaining time from the undercounted figure, so the 1-hour and 10-minute warnings were **arithmetically unable to fire** — the lab was never told the run was ending (rule 4). This was the one finding that caused something *not to happen* rather than merely displaying a wrong number, and it was silent: nothing logged, nothing raised, only the lab noticing;
- lux readings never taken (a sensor unplugged mid-cycle) were written as `0.0000E+00` — in the same row where a missing *temperature* was correctly written as an empty cell (rule 3).

**How it got there is the part worth remembering: a partial fix.** Someone correctly noticed the cycle counter fired the duration trap half an interval early and moved the trap to wall-clock — and left the display, the file column, the chart axis and the reminders on the count. Before that edit everything was consistent-but-wrong; after it there were two clocks. **Changing one consumer of a quantity is never the whole job. Change the quantity, or change every consumer.**

Three more, later, of the same class — recorded because the rule kept being paid for:

- **2026-08-06, the orange banner.** *"This run is taking longer per cycle than configured, so it will finish about 2 days, 22 hours later than planned"* — shown to the lab after a 38-hour mains outage. It blamed the software for a power cut, its number did not reconcile with the countdown two lines above it (two answers to "when does this end", stacked), and it was the thing the lab reacted to: *"embarrassing"*. A banner that diagnoses must diagnose correctly, or it must not diagnose at all. The unarguable line — *"9,601 measurements to go"* — needed no prediction.
- **2026-08-28, the chart caption.** "18-day moving average" over a window that was 18 *display points*, about 5.7 hours — off by ~75×, found while the owner was using it to judge how far an outage would be diluted. The directive itself had prescribed the wrong wording; the code implemented it faithfully. Rule 6.
- **2026-08-28, the meter log.** A stopped session never cleared its buffers, so the next session's opening rows carried the previous session's readings under fresh timestamps. Rule 3, in every meter log ever taken.

### A blank is only honest when it cannot be mistaken for data

Codex's "blank beats stale, and both beat missing" holds for a page. Icarus found the case where it fails: after a schema upgrade left 42,606 rows present but unreachable by the chart's query, the chart came up **empty — and an empty degradation chart looks like a result** (a flat line reads as "the lamps didn't degrade"). For any surface where zero, flat or empty is a legitimate value, a blank is not visibly a failure. Then the failure must be *said*: a label, a warning, a count that does not add up — never just absence.

### Guards must measure the real cost, not the configured one

Icarus's pre-start check summed the configured waits (54 s) against a 60 s interval and passed every time; the real cycle cost 59.95 s once sensor reads, timer slop and the commit were counted. **A guard that checks arithmetic the system does not obey passes everything.** Measure the cost from the running thing's own log (Icarus: 63,909 screen visits) and put the measured figure on screen before Start. And label estimates as estimates: the overhead constants that replaced the guess were *"estimates wearing constants' clothing"* until a run on the current build re-measured them.

---

## Occam's Razor — Simplest Solution That Works

When there are two ways to solve a problem, choose the simpler one. Always.

- If Apple's SDK already does something, use it rather than building a custom version
- If a problem can be solved with 20 lines of straightforward code or 100 lines of clever code, write 20 lines
- Avoid "future-proofing" that adds complexity now for benefits that may never materialize. Build for what the app does today. Refactor when requirements actually change.
- When evaluating a library or approach: "Is this the simplest thing that will work reliably?" — not "Is this the most powerful option?"

**Clever code is a liability. Simple code is an asset.**

**Where this ranks *(Revised 2026-09-04, Icarus)*:** below Quantitative Integrity, above everything else. The simplest thing that works must still be *true* — see the section above for the two simple lines that were not. And "simplest" cuts the other way too: on Icarus the assistant proposed decimal cycle durations, which would have retyped a persisted field (the exact change class that had wiped the store once). The owner: *"the lab did not ask for that, I was being clever."* Unasked-for capability is the opposite of Occam.

---

## Comments Are Part of the Deliverable

Every file should be legible to a non-developer who is willing to read carefully. Comments are not optional and are not a courtesy — they are part of the deliverable. Code without comments is incomplete code.

**What this means in practice:**

- **File header comments:** Every source file begins with a comment explaining what this file is, why it exists, and how it fits into the module it belongs to.
- **Function/method comments:** Every function has a plain-English comment above it — what it does, what goes in, what comes out — before the signature.
- **Inline comments:** Any line or block that isn't immediately obvious to a non-developer gets an inline comment. When in doubt, comment.
- **Decision comments:** When a specific approach was chosen over an alternative and it's not obvious why, a comment explains the reasoning. Example: *"We copy the file here rather than using a security-scoped bookmark because the bookmark becomes invalid after the app restarts."*
- **Section dividers:** Long files use `// MARK: - Section Name` to create navigable sections.

---

## Never Lie in a Comment

A comment that describes what the code *used to do*, or what a developer *intended it to do*, rather than what it *actually does*, is worse than no comment at all.

When code is changed, its comments are updated in the same commit. Stale comments that contradict the code are deleted, not left in place. There is no such thing as a comment that is "close enough" — it either accurately describes the code or it does not exist.

**The same rule covers every sentence the app or its documents make *(Revised 2026-09-04, Icarus)*:**

- **User-facing strings.** When the premise behind a message changes, the message is a lie until it is edited. Icarus's UPS alert told the operator *"The Mac may shut down when the battery empties"* and, on restore, that *"the outage killed the projectors too"* — both true when written, both false the day the projectors got their own UPS. Hardware moving underneath a string is a comment going stale.
- **Directive lines.** A directive that still says *"OWED, not yet built"* about something the code has as a Debug button — and code that quietly stopped doing what its directive describes — are the same defect in both directions. On 2026-07-16 the owner assumed a colour-verification step was active because the directive implied it; it was a button nobody had pressed. *"That can't happen."* Rule since: **nothing lands without its directive line updated in the same commit, and a handoff states what is WIRED, not what EXISTS.**
- **"Implemented" versus "verified".** Never write the first when you mean the second. The owner tracks the distinction and it was the source of real anger. A service file that exists and is called from nowhere is not a feature.
- **Rehearsal artefacts.** Anything a drill produces — a simulated outage, an injected fault — is marked `SIMULATED` in every file, log line and message it touches, so it can never be read later as a real event. Icarus marks its UPS-simulation output that way for exactly this reason.

---

## Document the Journey, Not Just the Destination

This is the most important commenting principle for AI-assisted development.

When a working solution was reached after several attempts — which is normal — the final comment must capture:

- What approaches were tried and why they didn't work
- What the working approach is and **why** it works (not just what it does)
- Any non-obvious constraint that made earlier attempts fail (an API limitation, a timing issue, a platform quirk)

**Why this matters:** If a future developer (or AI assistant) looks at a working solution and doesn't understand why it was written that way, they will "simplify" it and break it. The comment is the defence against that regression. When needed, say explicitly: *"This approach was chosen because [X]. Earlier attempts using [Y] failed because [Z]. Do not change this without understanding that constraint."*

This applies equally to architectural decisions in directives and to individual functions in code.

---

## One File, One Job

No source file should try to do everything. Each file has one responsibility.

- A view file contains one view (or a tightly related family of sub-views). It does not contain business logic.
- A model file contains one data model. It does not contain UI code.
- A service or manager file handles one concern.
- If a file is growing beyond ~200 lines, it is probably doing too many things. Break it up.
- Use language-appropriate mechanisms to split large types by concern (Swift's `extension`, Python's modules, etc.) rather than putting everything in one file.
- The project structure should be navigable. A developer (or AI assistant) should be able to open the project and understand where everything lives within a few minutes.

---

## Work With the Platform, Not Against It

Every platform has strong, opinionated design patterns. Fighting those patterns to achieve a specific effect is almost always a losing battle — it produces fragile code that breaks with OS updates, behaves unexpectedly, and takes far longer to build than the result justifies.

**The rule:** If achieving a desired behaviour requires overriding, subclassing, or working around a standard platform component in a non-trivial way, stop and reconsider whether it is worth it.

**The flag:** When this situation arises, Claude Code must say explicitly:

> *"This approach would require working against how [framework] handles [X]. Here's what the standard behaviour looks like, and here's what it would take to override it. Given the simplicity principle, I'd recommend accepting the standard behaviour. Want to proceed anyway?"*

This is not a veto — the project owner decides. But the flag must be raised before any fighting-the-framework code is written.

**A corollary learned the hard way *(learned on Codex)*:** "the platform vendor's own app does it" proves the behaviour is possible *for the vendor*, not reachable for you. Apple Books' page curl, its position model and its pagination were all studied as targets; some of what Books does rests on private machinery no third-party app can call. Before grinding toward a reference app's behaviour, ask once whether it is achievable with public API — and note that your own architecture (Codex photographs a rendering engine's output and animates the photograph) may itself be a workaround for a limit the reference app does not have. That is a legitimate design, not a failure, as long as it was chosen knowingly.

---

## Every Wait Has a Timeout and a Fallback *(learned on Codex)*

Any wait the user's screen sits behind — an `await`, a poll, a readiness gate, a "loading…" state — is paired, **at the moment it is written**, with two things:

1. **A deadline.** A bounded loop with an error branch, never a bare await on library code.
2. **A fallback the user can see or act on.** An error message, a retry, or a degraded-but-honest result.

**Why:** an unbounded wait turns any rare failure (a corrupt file, a stuck server, a lagging cloud read) into a frozen screen with no information — strictly worse than the failure itself, because the failure at least says what happened. Codex shipped two of these before the rule existed: a spinner that ran for 253 seconds behind "Opening book…", and a book-open call that could spin forever on a corrupt file. The owner, on finding the second: *"everything should have a timeout and a fall back."*

**The wider form, for anything that gates the screen:** never trust a single signal with the user's screen. A readiness gate that waits for one event to fire must also give up on a clock and show something honest.

**In review:** hunt for awaits with no timeout the same way you hunt for force-unwraps. They are the same kind of bug — a claim that the unhappy path cannot happen.

---

## Never Silently Lose the User's Content *(learned on Codex)*

When a mechanism cannot present some of the user's content correctly, the acceptable outcomes are, in order:

1. **Present it correctly by another route.** (Codex: pad a chapter's short last page to a whole spread so the paging engine's own step reaches it.)
2. **Refuse visibly.** A page turn that does not happen; a blank leaf; an honest "could not load." The user can see a refusal and work around it.

**Never** a silent skip past content, and never content cut off mid-line presented as if it were complete.

**Why:** a silent skip *looks* like a clean fix in the log — no errors, the user is unstuck — and it is worse than being stuck. Being stuck is visible. Missing lines are invisible until the story stops making sense. The owner, on a proposed workaround that dropped a chapter's last few lines: *"99% of a story is an incomplete story."*

**The tell to watch for in your own reasoning:** any fix described with "loses a few lines," "skips the tail," or "lesser evil." That is the unacceptable branch. Stop and find route 1 or route 2.

The general form: **blank beats stale, and both beat missing.** A blank is visible and actionable. A stale page is a lie the user cannot detect. Missing content is a lie the user detects too late.

---

## A Rule About What Is Recorded Never Decides What Is Displayed *(learned on Codex)*

A guard written to protect what the app *saves* must not be allowed to suppress what the app *shows*. Codex hit this three times in one evening (2026-08-24), each costing a build-and-test round, and each with a perfectly plausible comment above it:

- "A post-jump position may be stale, so don't save it" — deleted the whole position, so the page was stamped with no page number at all.
- "The engine never reported a position, so don't save it" — blocked a *display estimate* that never read the position in the first place.
- A five-guard chain protecting a saved fraction blocked a *count* that needed only a chapter name and an index.

**The rule: every guard names its consumer.** "The position of record" — then it belongs in the save path and nowhere else. "The page number on screen" — then it may not touch the save-path's inputs, because the display is not derived from them. A guard that cannot name what it protects is in the wrong place.

**Why it bites:** suppression is cheap to write, and its cost lands on a surface the author was not thinking about. The comments above the three guards all made claims the logs flatly disproved ("a missing save costs nothing here" — it cost the page number). The record and the display are different consumers with different tolerances: the record must never be wrong; the display may be an honest estimate.

**A corollary for anything baked at a fixed moment** (a snapshot, a rendered image, an exported file): whatever is suppressed at bake time is suppressed permanently — there is no later pass. Treat bake-time as a one-way door and put display guards *after* it, not before.

**The third consumer — what makes the process *stop* *(Revised 2026-09-04, Icarus)*.** Icarus found a case where two consumers disagreed and the fix went the wrong way. The run's stop rule originally ended on a cycle *count* dressed as a clock; it fired half an interval early, so it was moved to true wall-clock — which made the stop rule agree with the *display* instead of making the display honest. The owner's actual contract was the count: *"If we spec a cycle time of 60 seconds, for 90 days, and the experiment lets us set that, we expect 129,600 rows of data."* Under the clock rule the first five-day run silently delivered 7,101 rows of the 7,205 owed. So: what a system *records*, what it *displays*, and what makes it *stop* are three consumers. Name all three when a quantity is specified, and when two disagree, decide from the contract which one is wrong — not from which is easier to move.

---

## Resources Ship Regardless of `#if DEBUG` *(learned on Codex)*

`#if DEBUG` governs **code**, not **resources**. In an Xcode project using file-system-synchronized groups (the default since Xcode 16), every file placed under the app's folder joins the target automatically — there is no per-file entry for anyone to review and nobody ever ticks a box.

On 2026-08-21, three sample epubs sat in the app folder for a DEBUG-only seeding feature. The seeding code was correctly compiled out of Release. The Release archive uploaded to TestFlight still carried all three files — 5 MB the shipped code could not even use — and two were in copyright. The owner: *"so, did we upload those copyrighted books up to apple????"* The build was withdrawn from review with zero outside installs, the repository was made private, and 376 commits of history were rewritten.

**The rules:**

- **Nothing that is not yours lives under the app's synchronized folder.** Sample material, test fixtures from third parties, anything copyrighted goes in a repo-root folder outside every synchronized group, and that folder is `.gitignore`d.
- **To exclude a file, move it out.** A target-membership exception in the File Inspector also works, but a move shows up in `git log` and cannot be silently undone.
- **Verify the archive, never the reasoning.** Before any upload that adds resources, inspect the archive itself:

  ```
  find <name>.xcarchive -iname "*.<resource extension>"
  ```

  This is a line item on `TEMPLATES/RELEASE_CHECKLIST.md`, not a thing to remember.

---

---

## Every Tunable Value Has a Settings Home

Nothing in the app is hardcoded without a conscious decision that it should be. Every value a user might reasonably want to adjust gets a setting, even if it requires several taps to reach.

**Two-tier settings pattern:**
- **Surface settings:** visible immediately. The things most users will touch.
- **Advanced settings:** behind an "Advanced" row or section. Power-user controls that most users never need, but that should exist when needed.

The rule: if a value was discussed during planning as a tuneable number or behaviour, it becomes a setting. When in doubt, make it a setting and put it in Advanced with a clear inline explanation.

This is not an invitation to build a settings screen that requires a manual. Advanced settings should still be well-labelled. But they should exist.

### What Codex learned about the settings home *(learned on Codex)*

The two-tier pattern held, but four refinements were paid for in test rounds:

- **Order by frequency of change, not by category.** The controls a reader touches daily (text size, theme, page-turn style) sit at the top, uncollapsed. Everything else lives in collapsible groups, and *which groups are open is remembered per device* — the reader who opened "Typography" once should find it open next time. Codex's 2026-09-03 "palettes tidy" reorganised both settings surfaces this way after a HIG review; the earlier category-ordered layout put the daily controls three groups down.
- **Which settings SYNC and which are PER DEVICE is an explicit decision, made per setting.** It is not a property of "settings" as a class. On 2026-09-03 the owner ruled that typography (size, margins, font, theme) is *per device* — a size chosen on the phone must not land on the iPads, because "font size and margins are facts about the glass in hand, not about the reader." Until that ruling, one synced record silently overwrote every device's typography with whichever was saved last. Decide this in the directive's settings section for every setting, and store per-device values in a store that never syncs (Codex: a second, local-only SwiftData configuration keyed by hardware model — the vendor identifier resets on reinstall and is the wrong key).
- **Engineering controls live behind one switch, not in the shipping sheet.** Codex's page-curl tuning sliders (roll fatness, lay-back fraction, dead angle) are real settings under this principle — and they are not what a reader opening Settings should meet. They sit under a single "Diagnostics" switch; off, the group is not there. The principle says the knob exists; it does not say where.
- **A tuning control has no dead travel.** Every position on a slider must produce a visibly different *working* result. Codex's first curl-radius slider shipped with a range picked before the page could turn at all; above a third of its travel the roll was too fat to fold over and no drag could complete a turn. The owner found it in a minute of use: *"why would it ever be too big to function?"* The fix is never to delete the knob — the owner wants to tune — it is to validate the range against the *running* thing and cut the range that cannot work. Checking ranges is the assistant's job; the owner should not be the one discovering dead sliders.
- **Name and explain controls by feel, not by parameter.** "Roll fatness," not "Radius." "The roll is too fat to turn over," not "arc length is π × radius." A control the owner cannot form an intuition about is usually a knob that should not exist at that level; treat "I don't know what this does" as a defect report about the control, not a gap in the owner's understanding.

### What Icarus learned about the settings home *(Revised 2026-09-04, Icarus)*

- **Every setting has a *scope*, decided per setting — and the scope follows what the value describes.** Codex's sync-versus-per-device ruling is one instance of a general question. On Icarus the same question was "app-level or per-experiment?", and the owner's test was consistent: a value that describes the **hardware** (which display is the projector feed, the UPS battery deadline, the idle-display pattern) is app-level and moves with the rig; a value that describes **one run** (auto-resume after a crash, which bays are retired) is per-experiment. Getting it wrong either forgets a rig fact when the run changes or drags a one-run choice into the next. Write the scope in the directive's settings table.
- **A setting that would change a persisted type is not a setting; it is a migration.** See Occam's Razor above — the decimal-duration knob nobody asked for.
- **One quantity, one name on screen.** Icarus's setup screen said "reporting interval" in one place and "cycle duration" in another for the same value. The owner's ruling: *"Cycle duration", never "reporting interval", in the UI* — and the rename was UI-only, because the model property and the file header key keep their names for compatibility. The user's word and the code's word may differ; the *user's* words may not differ from each other.
- **Compile-time constants with a `// TODO: settings home` are the failure mode this section exists to prevent.** Icarus's fault thresholds (±15 % deviation, 50 % contrast collapse, a 5-cycle window) shipped as code constants with exactly that comment, and the lab's first real run showed the 15 % arm firing on all six bays after an outage. Give the knob its Advanced home when the constant is written; the first real run is when the number needs tuning, and that is the worst moment to be editing source.

---

## Every Build Is Identifiable

Every build of the app produces a unique, automatically-generated build identifier that is visible to the user in an About screen. No two builds are ever indistinguishable.

This is a discipline for the project owner first, not for end users. When troubleshooting — especially via screenshots, recordings, or a verbal description from someone else — the single most useful piece of information is "which build is this?" Without it, you spend the first ten minutes of every debugging session trying to figure out whether the user is running the build with the fix or the one before it.

**The rule:** the build identifier is set by an automated script at build time, not maintained by hand. A human cannot be relied on to remember to increment a number. They will forget, exactly when it matters most.

### The Approach

`CFBundleVersion` (the build number on Apple platforms) is set by an automated build phase to a compact `YYMMDDhhmm` timestamp (10 digits, e.g. `2605041335`). The About screen displays three things:

- The marketing version (`CFBundleShortVersionString`, e.g. `1.2.0`) — set by hand at release time
- The build timestamp — set automatically on every build
- The short git SHA of `HEAD` at build time — set automatically on every build, with a trailing `+` if the working tree was dirty

Example About display: `1.2.0 (2605041335 · a7672bc+)`

The `+` on the SHA matters. A dirty working tree means the build does not correspond to any committed state — without the marker, the SHA alone is misleading.

### Why Timestamp Rather Than Commit Count

A common alternative is to set the build number to `git rev-list --count HEAD` so it tracks commits. This fails in the exact case the build identifier most needs to succeed: troubleshooting. During a debugging session you typically rebuild many times *without* committing — three rapid debug builds would all report the same build number. A timestamp is always unique and always monotonically increasing.

### App Store and TestFlight Compatibility

Apple's App Store and TestFlight require `CFBundleVersion` to be monotonically increasing per marketing version. A Unix timestamp satisfies this trivially — every new build has a larger value than the previous one. No special handling is needed when the project eventually ships through these channels. Plan for this from the first build, even on projects that are nowhere near submission yet; retrofitting it under deadline pressure is exactly the kind of thing that gets skipped.

### Implementation

The build-time automation uses two Run Script build phases — one runs before Compile Sources and generates a tracked-but-regenerated `BuildInfo.swift` containing the timestamp, SHA, and dirty marker; the other runs as the last build phase and mutates the *built* `Info.plist`'s `CFBundleVersion` on Release builds only (so no committed source file is touched on every build). The same setup works on iOS and macOS. What differs is the *display* layer: macOS apps can lean on `NSApplication.orderFrontStandardAboutPanel(_:)` with a custom credits dictionary; iOS apps need a custom About view.

The full reference implementation — both scripts, the placeholder file, the Run Script setup, the User Script Sandboxing build setting, About-screen wiring for both platforms, and the gotchas discovered during real-world implementation — lives in `TEMPLATES/BUILD_NUMBER_AUTOMATION.md` so it is followed exactly rather than re-derived. The directive in any new project's build `CLAUDE.md` must require this practice and point Claude Code at the reference template — Claude Code should not invent its own version.

### What happened when it was skipped *(learned on Codex)*

Codex did **not** install this from day one. The build number stayed a hand-maintained `CURRENT_PROJECT_VERSION`, date-based (`YYYYMMDDNN`, bump the last two digits for a second archive in a day). It failed exactly as this section predicts, and more than once:

- **2026-09-01:** minutes before an archive, the number still read the previous day's, and the log stamp still described a feature from two builds earlier. The owner: *"should we be doing that every build so it does not get forgotten?"* The answer is to generate them, not to remember harder.
- **2026-09-03:** the archive on disk carries `2026090201` — the **same** number as the previous day's TestFlight upload. Whatever App Store Connect ended up holding, the archive and the record disagree, and the checklist step that went wrong that day ("add the build to the tester group") was being done against a number nobody could trust.

**What did work, and is the more valuable half:** a one-line **stamp written to the log at launch** (`[curl-build] stamp: …`), a short word or two naming what is in the build. Every log the assistant reads begins with checking that line — before interpreting anything else — because twice in one day (2026-08-17) a session spent rounds debugging code that was not in the running binary. The stamp is what made "which build is this?" answerable from a tester's log rather than from a screenshot of an About screen the tester never opens.

Two rules follow, and both go in the directive:

1. **The stamp carries the git commit hash**, generated by the build phase. A hand-typed description goes stale; a hash cannot. It identifies the exact code that produced the log rather than the last thing anyone remembered to type.
2. **The stamp is the assistant's to check, never the owner's to report.** Never write "the stamp should read X" to the owner or ask for a log line — the owner reports what is on the glass; the assistant reads the logs (see "Diagnostics" in `07`). On 2026-09-03 the owner, told a stamp "should read TAPS2": *"I have no idea where it would read that."*

**And one boundary, ruled by the owner:** generating the identifier is automated. **Uploading to TestFlight is not, and must not be proposed again.** Offered on 2026-09-01 (gate a cloud build to a tag so a push does the upload); the answer was *"absolutely not."* The owner archives and uploads by hand, deliberately, so that a push is never a release. Automate the number; leave the ship decision in human hands. (`TEMPLATES/RELEASE_CHECKLIST.md` carries the hand steps.)

### What happened when it was installed on day one *(Revised 2026-09-04, Icarus)*

Icarus followed the template on its first day (2026-05-19), on macOS, with the About panel via `orderFrontStandardAboutPanel`. It worked, and the kit was right: every lab report names its build (*"Build 2607231210"*), every handoff records what the lab is running, and "which build is this?" has never cost a round. Two things the template does not say, both paid for:

- **The stamp is a detector, not a preventer.** On 2026-07-31 the owner said *"increment the version number and I will build and send for notarization while you build release notes."* The assistant did both and raised committing only when asked later — by which time 1.2.0 was on the lab Mac stamped `7641350+`: the *previous* commit's SHA with a dirty marker, so the shipped binary cannot be traced to the tree that made it. The owner: *"it's your job to remember these things when I say I am going to distribute."* Rule since: **the moment the owner says build, notarize, archive or distribute, say COMMIT FIRST, unprompted, before anything else.** If a dirty build already went out, mitigate by documentation — commit immediately and record which commit that stamp corresponds to. And **read the About panel back before the build leaves the machine**: version, fresh timestamp, SHA with no `+`. One glance catches a dirty tree, a skipped version bump and a stale build.
- **Two different binaries must never share a version number.** The lab keeps every build side by side in Applications, named by version, and picks from that folder by name — usually at the moment something has gone wrong. So `MARKETING_VERSION` bumps whenever the content changes, even for a one-line fix; and it bumps **once per shipped build**, by the largest increment the release earns, never once per fix. Icarus notarized a 1.3.0's worth of work as 1.2.0 once (2026-08-06) because the rules were written but the *order* was not — see the macOS variant in `TEMPLATES/RELEASE_CHECKLIST.md`.

**Put other provenance in the About panel too.** When Icarus's versioned store files started being copied forward on upgrade, the About panel gained a line saying which file this build opened and where it was copied from — the question a support session asks first after any upgrade.

---

## Development Signing Doesn't Expire

Local development builds are signed with an identity whose expiry is not on the developer's maintenance radar — never with Xcode's auto-provisioned **Personal Team** certificate.

Personal Team certs (the free identity Xcode auto-creates when a developer signs in with an Apple ID and no paid membership) have a one-year validity and are subject to silent revocation when Apple rotates issuing infrastructure. Every revocation breaks local builds with cryptic signing errors until re-provisioning, and the keychain accumulates `CSSMERR_TP_CERT_REVOKED` entries. This is not a hypothetical failure mode; it is the default failure mode and it bites at the worst possible moment, mid-debug.

**The rule:** every project's development signing identity must be one that Xcode renews for you or that lasts years, never a default that resets every twelve months and can vanish. Two paths satisfy the principle; Personal Team does not.

### Path 1 — a paid Apple Developer Program team (the primary path) *(revised 2026-09-04)*

Once the owner holds a paid membership, the answer is Xcode's **automatic signing against the real team** (`CODE_SIGN_STYLE = Automatic`, `DEVELOPMENT_TEAM = <team id>`). Apple Development certificates issued under a paid team still carry a one-year validity, but Xcode renews them silently during a normal build and nothing is revoked underneath you — the churn that this section exists to avoid comes from the Personal Team tier, not from the yearly date. Codex has run this way since the owner's membership activated on 2026-05-11, through four months and several hundred device builds, without a single signing interruption.

Under this path the development identity and the distribution identity are both Apple-issued and both managed by Xcode; there is no "switch signing back before archiving" step. What remains is the ordinary release discipline in `TEMPLATES/RELEASE_CHECKLIST.md`: archive from the right branch, verify the archive's contents, upload by hand.

**If the project will ever need CloudKit, iCloud Drive, push, or TestFlight, the paid membership is required anyway** — Codex's sync module was blocked on it for its first six weeks. Get the membership at project start rather than treating it as a release-time cost.

### Path 2 — a self-signed certificate (the fallback, for owners without a membership)

For an owner who does not yet have a paid membership, a self-signed certificate created in Keychain Access with a 10-year validity is the right tool. Conflating "the cert that signs distribution builds" with "the cert that signs local builds" is a category error — the distribution cert is precious (loss = re-issuance through Apple Connect), the development cert is disposable (loss = recreate in 30 seconds). Keep them separate.

The signing identity is set explicitly in Build Settings via `CODE_SIGN_STYLE = Manual` and `CODE_SIGN_IDENTITY = "<CertName>"`, applied to every target that loads into the host app's process — app target, test bundle, and any framework targets the app loads at runtime. This is required because Hardened Runtime's library validation rejects loads where the loaded code's `TeamIdentifier` does not match the host's; mismatched signing identities across in-process targets crash the app at launch or fail tests with cryptic `mapping process and mapped file (non-platform) have different Team IDs` errors.

Self-signed builds only run on the developer's own machine. Distribution-ready builds still need a Developer ID Application certificate and notarization (or App Store distribution). A project on this path must therefore carry an explicit release step: "switch signing to the Apple-issued identity before archiving."

The full reference implementation for this path — the certificate-creation procedure, the per-target Build Settings changes, the Debug-only library-validation entitlements exception that keeps XCTest and Xcode 16's debug-dylib feature working, the verification commands, and the gotchas discovered during real-world implementation — lives in `TEMPLATES/DEVELOPMENT_SIGNING.md`.

### Which path a new project takes

The build `CLAUDE.md` names the path in one line. Path 1 when a paid team exists; Path 2 until it does, with the switch to Path 1 recorded as a card the day the membership activates.

**Path 1 on macOS, outside the App Store *(Revised 2026-09-04, Icarus)*:** Icarus signs every build — local and release — with the **Developer ID Application** identity, Hardened Runtime on, App Sandbox off (recorded with rationale in its overall directive), and ships notarized, stapled builds by hand. Four months, several hundred builds, no signing interruption; there is no "switch back before archiving" step. One fact worth knowing: **notarization is not required to *run* a self-built Developer ID build on another Mac — only the quarantine flag matters** (`xattr -dr com.apple.quarantine`, or copy it over with `scp`/`rsync`). Notarization is a scanning service, not publication; a submission can be abandoned at no cost, so a wrong build is always cheaper to rebuild than to ship.

---

## Anti-Goals Are as Important as Goals

Every project spec should state explicitly what it is NOT building, and why. Anti-goals prevent scope creep, prevent Claude Code from adding "helpful" features that conflict with the project's philosophy, and preserve the integrity of the design.

Anti-goals should be stated with the same authority as goals. "We are not building X" is a decision, not an absence of a decision.

Examples of well-stated anti-goals:
- *"No DRM support. This is a DRM-free-only application."*
- *"No gamification — no reading streaks, badges, or goals."*
- *"No account creation or login. The platform's identity layer handles this."*
- *"No social features in v1."*

State anti-goals in the overall directive and reference them in module directives where relevant.

**Lifting one is also a decision, and it leaves the same trail *(Revised 2026-09-04, Icarus)*.** Icarus began with fourteen anti-goals and lifted six of them in four months as the lab's needs surfaced (temperature sampling, a chart, notifications, an in-app editor…). Each is still in the list, **struck through with the date it fell and what replaced it** — never deleted — so a session that remembers the old rule finds its supersession rather than re-arguing it. A *carve-out* is recorded the same way, with its boundary stated: Icarus's "no networked operation" anti-goal stands, except for one outbound heartbeat to a lab-controlled address, off by default, carrying no measurements — written into the anti-goal itself so the exception cannot quietly widen.

---

## Three Ways, All of Them Right — the discoverability rule *(learned on Codex)*

The old Apple paradigm, in the owner's words — the one consultants used to teach, and which the platform has been quietly abandoning for a decade:

> *There are usually three ways to do anything, and all of them are right. The best one is the one that occurs to you.*

Menu, keyboard, toolbar, contextual — every path equally supported, so the user's instinct is correct by construction. The system meets them wherever they reach, instead of making them guess which single door was left unlocked.

**The enforceable half:** nothing may be reachable **only** by an unhinted gesture. A gesture may be a *shortcut* to something that also has a visible path. Never the only path.

**And a control that must be learned is not an affordance.** A `•••` overflow menu and a swipe-to-reveal have the same defect — they work only for people who already know they are there. The owner, a consultant, on being offered `•••` as the fix for a swipe-only action: *"barely anyone who is not a power user knows what … means."* His standard: *"a hidden feature with no hint that it exists really does not exist."* Prefer visible, self-describing controls — a share arrow, a trash can. Mis-tap risk on a visible destructive control is answered by a confirmation, never by hiding the control.

**This does not forbid clean surfaces.** Three things separate legitimate hiding from the kind that costs a real tester a feature:

| | legitimate | not |
|---|---|---|
| **How many reveals?** | ONE gesture, anywhere on the surface, restores EVERYTHING. Learned once, by accident, in the first ten seconds | a different secret for each action, in a different place; knowing one teaches nothing about the next |
| **What is hidden?** | a whole LAYER, with an obvious edge — the surface is plainly not everything, so something is plainly elsewhere | one action inside a surface that looks complete. Nothing about a list row suggests it has a hidden side |
| **What is it bought with?** | immersion. A page of a novel should look like a page of a novel; the hiding IS the feature | nothing. A list gains nothing from concealing its verbs — that is an idiom's side effect, not a decision |

So a reader's bare page with all its chrome behind one tap is right. Share and Delete reachable only by swiping a list row — which shipped on Codex, and which neither the owner nor his first outside tester found — is not. **The audience is not a power user.** For a v1.0 aimed at a dozen friends, the test is what *they* can find, not what a developer can.

**Why this needs writing down:** the framework forces none of it — `.swipeActions` is typed by a person. But the defaults, the sample code and the house style all make the hidden path the path of least resistance, so the outcome arrives by drift rather than by choice. A rule in the directive is how a default gets refused on purpose.

### Never hide what was explicitly asked for

Hiding by default is defensible while **browsing** — it reduces noise, and the user has not asked for anything in particular. It is indefensible in a **search**, because a search is the user saying exactly what they want. "I found it and I will not show you" is the worst of both. If someone searched for it by name, it appears, whatever state it is in — with its state shown, not its absence implied. A filter is a browsing convenience and must never silently outrank an explicit request.

---

## Never Ask a Question Whose Answer Changes Nothing *(learned on Codex)*

A prompt must be paid for by a real choice or a real loss. The owner: *"If everything fails to correctness silently, why bother the user at all."*

- Where there is a genuine alternative to offer, ask.
- Where there is no alternative, **tell, do not ask** — an "OK" button on news is not a decision.
- Where there is not even news, say nothing.

**Why:** a prompt nobody can act on trains people to dismiss the prompts that matter, which is how the important ones stop working. This is the same reasoning behind refusing to nag about permissions or content blocking.

### …but during testing, pester with information

A **stage ruling** from Codex's testing life (2026-09-03), not a permanent one: *"I would rather pester the reader with too much information and log that information. Apple's annoying habit of hiding information is not our goal today."* While an app is with a dozen testers, a surprise that is explained is a report and a surprise that is hidden is a mystery. So when choosing between a quiet default and a sentence on the glass, choose the sentence — and write the same fact to the log. The quieting is a later pass, done deliberately, once the surprises have stopped.

The two rules do not conflict: the first is about *questions*, the second about *information*. An explanatory strip with no button is allowed by both. An "OK" alert is forbidden by both.

---

## Design for Nobody Watching *(learned on Icarus)*

**Revised 2026-09-04, Icarus.** For anything that runs unattended — an instrument, a server, a long batch, an overnight job — the failure that matters is the one nobody is in the room for. Icarus paid for this on 2026-08-05: mains power failed at 06:44, the Mac restarted itself two minutes later, and the run then sat **stranded for 26 hours** with the projector lamps burning and nothing recorded. The app had been healthy to its last log line. Every gap after that was the design's:

- **The alarm path lived inside the runtime, which existed only after a human clicked Resume.** Nothing could alert because the thing that alerts had not been created.
- **The only signal was a dialog.** The recovery dialog's default button was a synthesized no-op "OK", and behind it sat a grey card on one tab that the modal itself covered. The owner, re-testing: *"I DID NOT see this warning, as it was under the other dialog."*
- **The dashboard said "Running".** The stored status meant "was measuring when last written"; the header read it as "is measuring now". A crashed run that claims health is a plausible reason nobody investigates.

The rules that came out of it, each general:

1. **The alarm must exist before the thing it alarms about.** Detect and alert from the earliest process state — launch, not "after resume" — with the recipients read from settings, not from a runtime that may not exist.
2. **A one-shot signal is a question nobody is there to answer.** The stranded-run alert became a red banner on every tab, a repeating sound, and a repeating message every ten minutes until a human acts. Same cadence as every other fault, deliberately shared. (This is the unattended form of "Never Ask a Question Whose Answer Changes Nothing": the question is fine; the *once* is the bug.)
3. **A status must not claim health it cannot prove.** "Running" is shown only when a live process is driving that run; otherwise the word is "Interrupted" and the control offered is the one that actually works.
4. **Say whether it is safe to act, from the hardware, not from memory.** Every ten-minute reminder now carries a per-bay verdict from an actual white/black test of the rig — *"all 6 bays pass the white/black check — safe to resume"* — so someone off-site can decide.
5. **Rehearse the outage without the outage.** Icarus's Debug menu fakes a UPS-on-battery reading *at the sensor level* so the whole real chain runs; every artefact is marked `SIMULATED`. Cutting real power to test was ruled out. The first rehearsal on the lab (2026-08-28) found a live bug the bench could not — which is what rehearsals are for.
6. **Alerts detect; only hardware rides through.** No amount of alarm design replaces a UPS. Record which of the two a mechanism is, so nobody mistakes a good alarm for protection.

**The tension to raise, not resolve silently:** an unattended system that keeps a consumable running while producing nothing is spending the resource the whole exercise exists to measure. The Icarus owner's hierarchy, verbatim: *"off is better than burning lamp time while not collecting data."* Any idle state that keeps something expensive running must justify what the expense buys — and dark, stopped, or idle is not automatically a fault to be cleared. Check first whether anything was being collected.

---

## The Engine Does Not Move the Pixels *(learned on Icarus)*

**Revised 2026-09-04, Icarus.** Split the app, in writing, into exactly two halves — the **Engine** (measuring, data flow, recording, persistence, recovery) and the **UI** (everything the operator sees and drives) — and make one rule enforced, not conventional: **an Engine change leaves every existing pixel where it was.** Layout, spacing, colour, font, wording, and every control's shape, size and position.

The incident (2026-07-10): during a lock/ready-state rework of the engine, the Home tab's large round centred Play button was silently demoted into a small blue pill inside a grey "Ready to run" card, and the always-visible status header was dropped entirely. Neither change was required by the engine work; both were bundled into it. A user who relies on a stable, familiar screen through long runs experiences an unasked-for visual change as a defect *even when the engine change itself is correct* — and it was the second such regression, which is what earned the rule a directive of its own.

- **Try the engine change with no UI change first.** Most "the UI has to change" beliefs are wrong; the new behaviour can usually feed the existing views unchanged.
- **If a UI change genuinely cannot be avoided, stop and ask** — in plain English, saying why, what would change on screen, and the options. The engine's need is a reason to *raise* the question, never a licence to answer it.
- **The one exception is adding something genuinely new** — a new value that needs a home, a new control for new behaviour. It is held to the surrounding style and still listed in the handoff. "I added a button" is not cover for restyling the three beside it.
- **Every handoff that includes engine work says either "No UI changes" or exactly what changed on screen and why.** Silence is the failure this rule prevents.

**Two companions, from the same owner:**

- **Reuse an *include*; never clone it.** An include (the lab's own word) is a single shared component used in many places, so a tweak to one instance appears everywhere. When asked for something *"like"* an existing element, parameterize that element — a read-only mode, a different label — rather than building a lookalike. A lookalike copy silently breaks the mental model that editing "the button" edits all of them. Fork only when the two are genuinely different things, and say why.
- **One piece of state behind any control shown in two places.** Two affordances for one concept read and write the same state, never two parallel code paths. On Icarus the experiment-lock control appeared in two places with separate wiring before this rule was written.

**Write the vocabulary down.** Icarus keeps a small glossary in the directive — *Engine, UI, layout, style, chrome, content, include, transport control* — with the rule that a new term is added to the table by agreement before anyone uses it. "The code" is banned as a synonym for the engine, because the UI is code too. This is how three parties (owner, customer, assistant) stop meaning different things by the same word.

---

## The Paired Intuition — a control is not finished until its failure is intuitive *(learned on Codex)*

Designing a control that behaves well when it works is half the job. When it does the wrong thing, **the user's instinctive reaction must BE the correct fix** — not a documented recovery, not a preference to go and find.

The owner's own worked example, from Codex's chapter scrubber: it snaps to chapter starts, which is right almost always. When it is wrong, a reader who lands on a chapter and *immediately drags again near the same spot* is plainly fighting the snap — so that second release lands exactly where dropped. Nobody has to find the preference. Snap stays on; the escape hatch is the thing you would do anyway.

Other instances of the same law: a swipe that does not turn the page (*"believable that I did not swipe far enough"* — the failure is acceptable on those grounds); a curl that falls back when released early; "blank beats wrong," where an honest blank is actionable and a stale page is an undetectable lie.

**What it forbids:** a control whose failure mode requires *knowledge* — a setting to find, a gesture to learn, a page of documentation — is unfinished, however good it is when it works.

**How to apply:** when designing any control, ask what happens when it does the wrong thing, and whether the user's first instinctive reaction fixes it. If the answer is "they'd have to know about X," redesign rather than document.

This is the same law as "write the manual early as a design test" from the other end: a failure that recovers by instinct is a paragraph the manual never has to write, so any failure the manual must explain is a control that has not met this law.

---

## Scrollable Panels Must Look Scrollable *(learned on Codex)*

A sheet presented at a partial height that cuts cleanly at a section boundary — no half-row, no scroll indicator — reads as "this is everything." Codex shipped a tuning panel that way; its main controls were below the fold and the owner lost a build-and-test round to it: *"if a panel is scrollable, it must obviously be scrollable. How would I have known it was?"*

**The rule:** (1) prefer sizing a sheet, panel or popover so *all* content is visible without scrolling; (2) if scrolling is unavoidable, the presented height must visibly slice through the middle of a row or control so the continuation is undeniable — never let the default detent land on a section boundary; (3) this applies to debug and tuning UI just as much as shipping UI, because the owner tests both.

---

## No Mandatory Onboarding

The first launch experience should get the user to the core value of the app as quickly as possible.

- No tutorial screens, no feature tours, no carousels
- No signup or account creation unless the core function requires it
- No permission requests beyond what is strictly needed for first-launch functionality
- No app review prompts early in the session — only after meaningful engagement
- No notifications unless the user explicitly enables them

The app should be self-explanatory. If it requires a tutorial, the UX needs to be simpler.

---

## No Dark Patterns

- No permission requests beyond what is strictly necessary
- No notifications the user didn't request
- No tracking or analytics without explicit consent
- No artificially imposed limitations designed to frustrate ("You've reached your daily limit")
- No UI designed to confuse or mislead the user into unwanted actions
- No upsells or upgrade prompts in the core reading/using experience

---

## Color Is Never the Sole Signal

Any information conveyed by color must also be conveyed by at least one other channel — text, an icon or shape, position, or some other non-color cue. Roughly 5–8% of male users have some form of color vision deficiency; for them, a red badge that is not also labelled, or a green/red status dot that has no checkmark/X, simply does not exist as information.

**The rule:** color is permitted as *reinforcement* of meaning. It is not permitted as the *sole* carrier of meaning. This is not a suggestion to drain color from the UI — color is a powerful communication tool and should be used. It is a rule about *redundancy*. Every information-bearing color choice has a non-color partner.

**Examples:**

- A status row uses both a colored dot AND a label ("Connected" / "Offline")
- An error message uses red AND a clear icon AND prefixes the text with "Error:"
- A diff view uses red/green AND uses `+` / `−` markers in the gutter
- Form validation uses a red border AND a text message under the field
- A "selected" state uses both a tint AND a checkmark, border, or position change

**Surfacing the question:** when Claude Code is implementing a UI element where color is the obvious way to convey state, it must pause and ask: "Is the color carrying information that nothing else is carrying?" If yes, add a second channel before shipping. If a project owner explicitly approves a color-only signal for a specific case — because adding redundancy would clutter the UI more than it helps — record that decision in the relevant module directive with the rationale, same as any other approved exception.

This was the first accessibility principle captured in this kit. Three more were paid for on Codex and follow.

**Overridden on Icarus, deliberately *(Revised 2026-09-04, Icarus)*.** On 2026-06-17 the owner de-scoped this rule, Dynamic Type, and the Protanomaly pairs for that project: *"There is one user, who does not need either."* A single-operator lab instrument, never distributed, with an operator who has no colour-vision or text-size need. The override was done the way the kit asks: the rule is struck through in the project's `CLAUDE.md`, overall directive and idioms file with the date and reason, the plain-English requirement (usability for a non-developer, not accessibility) was kept unstruck, and the SwiftUI audit dropped those two themes as findings. The kit rule stands; a project may set it aside when the whole audience is known and the decision is written down. It may not set it aside by drift.

---

## The Dark Adaptation Law — no area escapes the theme *(learned on Codex)*

For an app used at night, dark mode is not a colour preference. It is the feature that lets the user's eyes stay dark-adapted in a dark room — and a white flash undoes minutes of adaptation in a moment. The owner: *"If any big white areas appear in dark mode it is incredibly annoying and defeats the whole point."*

**The engineering form, which is the one to build against:** *no area escapes the theme.* Not "no large bright area" (which needs a judgment about how large and how bright) but a yes/no question askable of any single surface — does this respond to the app's theme? — answerable by reading the code one view at a time, without seeing it run.

**What it decides:**

- **A white flash is a functional failure, not cosmetic.** "It is only for a moment" is backwards — a moment is exactly the amount of white it takes. It supersedes "blank beats stale" at night: a *dark* blank is fine; a white blank is worse than a stale page.
- **The subsystem is irrelevant.** A snapshot, a material, a spinner, a sheet, an alert, or a surface nobody has written yet. So it cannot be fixed one site at a time and declared done; it needs a rule that catches later additions — host the themed surfaces in a colour scheme forced from the app's theme rather than sweeping colours one by one.
- **Dark is a designed theme, never an inversion — and never pure black.** The owner concurs with Apple that dark must be *"an actual theme designed to be dark."* A colour-flipped light theme is the placeholder, not the design. And on OLED — every iPhone since the X, so the *majority* dark-reading surface — a true-black background has the pixels genuinely off, and light text against it blooms and smears as the eye moves. Near-black, never `#000000`. Read every dark colour from one theme object so the single edit that settles the colour moves everything; never hardcode one.
- **Never inherit the app's appearance from the device.** Codex's two dark-mode readers, and the owner, all run their devices in *light* mode; for a dark-mode reader, the device being light is the normal case, not the edge. Thirteen SwiftUI surfaces (materials, system sheets) took their tint from the device setting, so at night every panel a reader raised was a pale slab over a dark page. Paint from the app's theme, never from the system colour scheme or a bare material. **And test theme work with the device in light mode** — that is where the escapes show.
- **Judge dark on the phone at night**, because that is the OLED surface and the real situation. An app tuned only on an iPad in daylight is half-judged.

**Reduce Motion is a real request, not a checkbox.** A tester asked for Codex's immersive reading mode with the page-curl animation off — an instant flick. That is the Reduce Motion answer and a feature in its own right; build the animation-free path as a first-class mode, not as a degraded fallback.

**Dynamic Type, scoped.** An app whose main surface has its own typography controls (a reader, an editor) applies Dynamic Type to its *chrome* — buttons, labels, settings — with a sensible cap, and leaves the content surface to its own controls. The owner ruled this scope explicitly rather than letting the platform default decide it.

---

## The Development Model Note

When a project is AI-assisted and directed by a non-developer owner, two additional rules apply:

1. **Plain English explanations.** When Claude Code surfaces a question or explains a decision, it is in plain English. Technical jargon is explained in context, not assumed.

2. **Summarize before starting.** Before writing code for a new module or feature, Claude Code summarizes what it is going to build and in what order, giving the owner a chance to redirect before work begins.

Four more rules were paid for on Codex, where the owner has said plainly: *"I cannot read or understand Swift code, so the comments are meaningless to me — they are for someone who understands Swift, and right now that is only you."* *(learned on Codex)*

3. **The code must export its memory.** Every decision comment in this section is invisible to a director who cannot read the language. On 2026-08-26, eleven problems in one day turned out to be already decided and written down in the code — four were already *built* — and none of it was visible to the owner, so the same ground was re-discovered or re-built. The fix: anything deliberately left unfinished carries a `// OWED:` comment (with `// WHY:` and `// TRIGGER:` beside it), written *for the owner* — say what a user would notice, never what the code omits. A script (`scripts/harvest_owed.py` on Codex) regenerates a `Docs/OWED.md` register from those comments and reports bare `TODO`s as invisible. The entry test: *would the owner be surprised?* An unbuilt module already in the directive's table is noise; work that looks finished from the outside is the whole value.

4. **Read the code; never ask the owner whether something is done.** A card's status is prose someone typed on a past day; the owner can only read the card, so his judgement is built on the stale words. The code cannot be stale about whether something exists — a grep settles it in a second, and twice in one session the grep contradicted the board. Bring a finding, not a question: "it is implemented in `File.swift` at line 787," not "do you remember if this is done?" The one fact still genuinely the owner's is whether a written thing *works on a device*.

5. **Explain by feel, not by geometry.** Describe behaviour as a physical thing doing something, in the words the owner used to ask. If a question needs mathematics to state, the question is wrong — fix the thing so the question disappears. Keep the mathematics in code comments and handoff entries, where a future session needs it.

6. **Time estimates are never in hours or days.** An assistant's estimates are learned from human coding pace and run an order of magnitude high; they mislead a director who plans around them. Size work by shape and risk — "one file, one build-and-report round" — never by the clock.

The disciplines for the *loop* itself — one build in flight, what to say before a test, who reads the logs — are in `07_TESTING_AND_DIAGNOSTICS.md`.

Icarus, directed by the same owner, added four more of the same kind — verify from disk yourself, flag a guess as a guess, enumerate open questions and stop, and say COMMIT FIRST before anything leaves the machine — each with the day it was paid for. They are in `08_WORKING_WITH_THE_OWNER.md` under "Facts Are the Assistant's Job" and "Authority" *(Revised 2026-09-04, Icarus)*.
