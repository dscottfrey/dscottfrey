# 05 — Architecture Decisions

How to make, record, and revisit architectural decisions in a way that survives across sessions, across branches, and across months.

**Revised 2026-09-04, Icarus.** Added from the Icarus project: a trigger that fired and then had its premise moved by the hardware; the chokepoint rule for defect families; the persistence rules for a store that must never be mutated in place; and the "not a bug" record.

---

## Why Architecture Decisions Deserve Special Treatment

Architecture decisions are the choices that are expensive to reverse: technology stack, persistence model, rendering approach, module boundaries, data formats, external dependencies. Getting them wrong costs weeks. Losing track of why they were made costs almost as much.

In AI-assisted development, the risk is compounded: a new Claude Code session starts without memory of previous sessions. If the reasoning behind an architectural decision lives only in a conversation, it is gone. The next session will either blindly follow the outcome without understanding it, or — worse — will "improve" a working solution into something broken because it didn't understand the constraint the original solution was navigating.

The architecture decision record is the defense against this.

---

## Record What Was Rejected, Not Just What Was Chosen

The most important thing to record is not what you chose — it's what you considered and did not choose, and why.

**Wrong:**
> The app uses CSS Columns for pagination.

**Right:**
> **Pagination: CSS Columns vs JavaScript scroll-position estimation**
> 
> Considered: JavaScript measurement of `scrollHeight` to derive page count dynamically.
> 
> Rejected because: content height in WKWebView is not stable at measurement time. Fonts swapping late, images loading asynchronously, and dynamic content can all change the height after the initial measurement, producing incorrect page counts and jumpy chapter transitions. This is the root cause of the pagination bugs seen in the initial implementation.
> 
> Chosen: CSS multi-column layout. The browser's layout engine divides the chapter into columns of exactly viewport dimensions. Page count is `scrollWidth ÷ columnWidth` — an integer the browser provides, not an estimate. Boundaries are deterministic and stable regardless of when measurement occurs.

The rejected option and the reason it was rejected are the most valuable parts. They are what prevent a future developer from "simplifying" the CSS Columns approach back to JavaScript measurement without realizing why that doesn't work.

**"Not a bug — recorded so nobody 'fixes' it" *(Revised 2026-09-04, Icarus)*.** The same record, one level down: a behaviour that *looks* wrong on inspection and is right, written up with the reason before someone corrects it. Every Icarus handoff carries a section by that name. Two entries from 2026-07-29: a single sensor dropping out triggers no hub restart, deliberately (restarting the hub would disrupt the bays still working); and an unplugged sensor is marked *"sensor offline"*, not *"no light"*, because the white screen read zero because nothing was listening, not because the bay was dark — with the line *"I initially recommended changing this and was wrong. Left as-is, deliberately."* The assistant's own wrong recommendation is the best reason to write the entry: the next session will have the same idea.

---

## The Trigger-to-Revisit Pattern

Every significant architectural decision includes a trigger: the specific condition under which the decision should be re-evaluated.

The trigger does two things:
1. Prevents endless second-guessing of a working decision
2. Ensures a decision that should be revisited actually gets revisited

**Format:**
> **Decision:** Custom epub parser rather than ReadiumStreamer.
> **Trigger to revisit:** More than three epub-compatibility workarounds have been added to the custom parser, or a class of epub files is consistently broken in a way that would require substantial additional parsing code to fix.

Without a trigger, decisions either get reconsidered constantly (expensive) or never (which allows technical debt to accumulate past the point where it would have been cheaper to act).

### The pattern fired for real — a worked example

Codex pinned the Readium toolkit at 3.8.0 (since upgraded to 3.11.0, as a card) with a recorded trigger: *"if the deprecated HTTP server API is removed, migrate to a custom URL-scheme handler."* Months later a session found the server was already obsolete upstream — the Navigator serves resources through its own scheme handler — and the recorded migration would have built something the library had already replaced. `Docs/READIUM_NOTES.md §1` records the correction: the trigger fired, the planned response was wrong, and the right move was deletion (the server, its adapter and a transitive dependency), not migration.

The note was first corrected from a changelog. A research pass challenged it — a changelog is not what compiles — and it was re-checked against the compiled checkout before anything was built. Both halves are the lesson: **the trigger is only useful if the response is re-decided when it fires**, and the re-decision is checked against the source, not the release notes.

### The pattern fired twice more — and the second time the premise had moved *(Revised 2026-09-04, Icarus)*

Icarus parked a decision on hardware the lab did not have: *should a UPS on battery pause the run?* The trigger, written into the directive on 2026-07-29: *"the owner reports a UPS has been installed. Discuss and decide before writing code. Do NOT infer it from the never-pause model."* Note the last sentence — the trigger names the tempting wrong inference so a future session cannot make it.

**It fired on 2026-08-06**, after a power loss stranded a run for 26 hours. Decided: pause immediately on battery, alert until cleared — an explicit exception to a settled rule, recorded as such. Built, with a Debug-menu simulator so it could be rehearsed without cutting power.

**Then the hardware moved twice under the decision (2026-08-28).** First, the lab installed the UPS but not its USB data cable, so the OS saw no UPS and the pause could not fire — *"chase the cable, not the code"*; a lab action, not a bug, and the memory says so in capitals so nobody goes looking for one. Second, the lab put the *projectors* on a UPS of their own. That broke the decision's premise: mains state had only ever been a proxy for "the lamps are lit", and now the lamps stay lit through an outage while the readings stay valid. Pausing would throw away good data. The decision was reopened with the sentence that matters: *"not re-litigating a settled question — the hardware moved underneath it."*

Two rules from it:

- **Record the premise, not only the decision.** A decision whose premise is a physical fact ("the projectors and the Mac lose power together") has that fact written beside it, so that when the fact changes the decision is visibly stale rather than silently wrong.
- **Distinguish "the mechanism cannot fire" from "the mechanism is wrong."** The first is a deployment fact to verify (`pmset -g ps` on the lab Mac); the second is a design question. Icarus nearly spent a session on code for a cable.

---

## Refuse at the Chokepoint *(Revised 2026-09-04, Icarus)*

When the same defect appears at several call sites, the fix is a refusal at the one place the dangerous thing is *created*, not a check in each caller.

Icarus's case (2026-08-06): the app painted its full-screen test window over the operator's own monitor — on a Mac reachable only by screen sharing — and did so three releases running. The root cause was a platform API whose name misleads (`NSScreen.main` is the screen with keyboard focus, not the primary display; and it is nil when nothing has focus, so "any screen that is not main" returns the primary). Four call sites passed `nil` for the preferred display and each guessed its own. Fixing the four was done — and a fifth site appeared three weeks later, in a component that borrowed the display for a minute and handed it back to nobody.

**The fix that held:** the single function that creates the window now refuses the primary display outright and logs it. Nothing can route around it. The upstream guards remain, but only so callers fail early with a readable message. And **a remembered choice is rejected too if it now resolves to the forbidden thing** — display identifiers are reassigned across reboots, so yesterday's projector can be today's monitor.

Generalised: for any resource that must never be misused — a display, a store file, a network endpoint, a delete — put the invariant where the resource is obtained, and treat each per-caller check as a courtesy, not a defence. A defect family with N sites has N+1.

**Two corollaries paid for the same week:**

- **Removing an escape hatch obliges you to guarantee what it recovered.** Icarus removed ⌘N and ⌘W to enforce a single window; a build swap with an editor window open then restored *only* the editor, and cancelling it left the app with no window and no way to make one. Hardening turned "annoying" into "unusable" until the main window was guaranteed at every launch.
- **Give the operator one key that fixes the worst state.** When the screen is covered, two shortcuts are one too many to remember. Icarus's ⌘⇧D pauses *and* releases the display, in that order (the order is load-bearing), is never disabled, and needs no dialog — because an invisible dialog is precisely what cannot be clicked.

---

## Persistence: Never Mutate the Only Copy *(Revised 2026-09-04, Icarus)*

An instrument's data store is the one artefact a bad decision cannot un-break. Icarus lost its store to a *purely additive* schema change on 2026-06-17 — three new optional columns, automatic lightweight migration, and the lab Mac came up empty while the dev Mac did not — then lost it again on 2026-07-08 to something first blamed on migration and actually caused by **another app writing to the same default store path** (an unsandboxed app that names no store URL gets the shared default, and so did a Markdown editor on the same machines). The rules it settled on are platform-agnostic:

1. **A new schema gets a new file; the old file is never overwritten.** Icarus names its store by schema version (`<App>-v<major>.<minor>.store`) and on upgrade *copies* the newest older file forward, then opens the copy. A bad migration cannot destroy the source; an archived old build always reopens its own data (which is what makes "swap the app for a bug fix mid-run" safe). Old files are kept on purpose — they are the archive guarantee — and when the owner moved one aside expecting a fresh start and an older one was silently copied forward instead, the fix was to make the swap *visible* (a provenance line in the About panel and the log), not to delete anything.
2. **Minor bump = additive copy; major bump = hand-mapped reconstruct.** Never rely on automatic inference across a rename or a retype. Every bump gets a `Docs/Migrations/v<N>.md` note. A retype of a persisted field is a schema change however small it looks — see the decimal-duration knob in `02`.
3. **Backstops in depth:** a timestamped backup before every open; a wipe-gate that refuses to proceed if the pre-open record count was non-zero and the opened store is empty.
4. **Migration risk is "reachable?", not only "survived?"** On 2026-07-30 a minor bump added two scalar key columns; the copy-forward filled 42,606 existing rows with the type default `0`, every query filtered on the real id, and the chart came up blank — *a blank that looks like a result*. Any new denormalised column on existing rows needs a backfill that runs, and an assertion that what is reachable by relationship is reachable by the new key. Icarus runs both at every launch, idempotently, and on unrepairable rows **warns and continues, never quits** — quitting repairs nothing and an instrument that will not launch mid-run is the worse failure.
5. **Name a single source of truth and make the rebuild executable, both ways, tested as a round trip.** Icarus's per-bay text files are the truth; the database is a cache. "Rebuild database from files" and "rebuild files from database" both exist as menu actions and the fault-code encoding was proven by round-tripping all 32,768 values — because *writer-then-reader tested separately proves nothing about a rebuild*. Anything deliberately kept in one copy only (Icarus's paused-state exception file) says so in its own header, with the trade-off, so a reader in ten years does not depend on the directive.
6. **Design mid-run features to need no schema change.** A per-experiment flag can live in preferences keyed by the record's id rather than as a new model field; Icarus did this for auto-resume and bay retirement because *"an additive change wiped the lab's store once already, and mid-run on a live 90-day experiment is the worst possible moment."*
7. **Schema work is cheap before real data exists and expensive after.** Land it before go-live. Icarus's go-live slipped three times and each slip was spent on schema and endurance items, not polish, on exactly this reasoning.

The platform-specific details (relationship arrays that go quadratic at scale, reconstruction rows with nil relationships that break joins) are in `06_SWIFT_SWIFTUI_IDIOMS.md`.

---

## Where Decisions Live

- **In the overall directive:** project-wide decisions (technical stack, dependency policy, development philosophy)
- **In the relevant module directive:** module-specific decisions (pagination approach, data format, API choice)
- **In the open questions section:** decisions that are still open, and decisions that were closed (with ✅ and the resolution)
- **In handoff notes:** decisions to revisit in future sessions, with trigger conditions

Do not let decisions live only in conversation. The moment a decision is made, it goes into the directive.

---

## Cross-Module Decisions

Some architectural decisions affect multiple modules. When this happens:
- The decision lives in the module where it is most central
- Other affected modules cross-reference it by file and section
- When the decision is made or changed, update all affected modules

**Example:** The annotation character offset type (Int vs Double) affected both the Annotation System and the Sync Engine. When it was unified to Int, both directives were updated and cross-referenced.

Cross-module consistency checks should be done before declaring the planning phase complete. Read all directives and look for:
- Data types defined in two places that must match
- Interfaces between modules that make different assumptions
- Settings that are referenced in multiple directives but only defined in one

---

## The Handoff Notes Pattern

Handoff notes are decisions or questions that are deliberately being deferred — not forgotten, but parked. They live in the planning `CLAUDE.md` under a "Handoff Notes" section.

A good handoff note includes:
- **What the note is about** — the decision or question being deferred
- **The current decision** — what was decided for now, and why it stands
- **The trigger to revisit** — what would cause this to be reopened
- **The migration path** — if the current decision is ever reversed, how hard is it to change?

**Example handoff note — and what happened to it:**
> **ReadiumNavigator — potential rendering layer**
>
> The pre-render-to-UIImage architecture was chosen. ReadiumNavigator's rendering pipeline was evaluated and rejected — it constrains the UI layer in ways that conflict with the page curl and interactive text selection design.
>
> Trigger to revisit: if the pre-render pipeline proves unmaintainable at scale, or if Apple's WebKit snapshot API changes in a way that breaks the architecture.
>
> Migration path: feasible but significant. The EpubLoader interface is narrow (ParsedEpub struct), so the rendering layer beneath it is swappable. However, adopting ReadiumNavigator would require rebuilding the UIPageViewController and interaction layer.

That note was written in spring 2026. **The trigger fired.** The custom pre-render pipeline could not paginate reliably (content height in a WKWebView is not stable at measurement time), and by August Codex had adopted ReadiumNavigator as the single live reading surface — and then *photographs* it to feed a Metal page curl, because the curl needs a picture and the Navigator is the only thing that can paginate. The "migration path" paragraph was right about the shape of the work and wrong about its size.

Two things to take from it. The note did its job: the decision was revisited deliberately, against a written trigger, with the rejected option's reasoning still on file. And a reversed decision is recorded as reversed — the original note stays, with the date and reason it fell, so nobody re-argues from a spec that no longer describes the app.

Handoff notes are not failures or admissions of incompleteness. They are an honest record of decisions that were made carefully and deferred deliberately.

---

## The Addendum Pattern for Experimental Work

When working on an experimental branch, features planned during that branch go in an addendum file — not the main directive.

**Why:** If the branch is killed, the main directive is clean and can be recertified. The addendum survives and can be folded back in if the branch is resumed.

**How:**
1. Create `[NN].1_[MODULE_ADDENDUM].md`
2. Begin with a header explaining its relationship to the parent directive and its status
3. Reference it from the main directive with a brief stub section
4. If the branch survives and the feature ships, fold the addendum back into the main directive and delete the addendum

---

## "The Reference App Does It" Proves Nothing About You

**Added 2026-09-04, from Codex.** A platform vendor's own apps ship against private frameworks, unshipped entitlements and internals no third party can link. So *"Apple Books does it"* establishes that a behaviour is possible **for Apple** — never that it is reachable from public API.

Treating a reference app's behaviour as a specification can set an unreachable target and hide that it is unreachable, because the failure always looks like your engineering not being good enough yet. On Codex, months of pagination work were downstream of exactly this: Books paginates through private WebKit SPI, and the only paginating path open to an App Store app is CSS multi-column. The one-Navigator-photographed architecture is a workaround for a real limit, not a shortfall of effort.

**How to apply:** when a reference behaviour will not reproduce, ask *"is this reachable with public API?"* **before** grinding on it — early, cheaply, out loud. If the answer is no or unknown, say so and let the owner decide whether to approximate, drop it, or spend anyway. Copy the reference app's *shape and interaction rules*; never assume its implementation is available. And do not reach for this as an excuse when something is merely hard — the claim needs the same evidence class as any other.

---

## Architecture Hygiene: Check Whether It Exists

Before an architectural addition, the same discipline as before a feature (`01_PLANNING_WORKFLOW.md`): grep for the type, read the directive, **check for zero callers**. On a mature AI-assisted codebase the commonest state of a capability is *built and unreachable*, and the second commonest is *ruled and forgotten*. Nine of twenty-one cards on one Codex day needed no building. An architecture decision made without that check may be a decision about something that already exists.

---

## Cross-Check Hardest When Most Confident

The wrong answers that survive are the well-evidenced ones. On Codex, a session read the dependency's compiled source — the best evidence available — found a branch, and asserted a mechanism, a protection and a derivable signal on it. All three were wrong: the function's only caller ran solely in a state where the branch could not be taken. One `grep` for the call site settled it, minutes before it would have been built on.

- **Read the call site before believing the branch.**
- Ask what single command would **falsify** the claim, and run that — not another confirming read.
- **Use a second party.** A research bot with web search and different blind spots, given the falsifiable form of the claim rather than the persuasive one, corrected the assistant and was corrected by it in the same session. That loop is the method.
- **Tag the evidence class in the sentence** — `[source]`, `[log]`, `[device]`, `[public]`, `[inferred]` — and hold to the rule that a conclusion is never stronger than its weakest tag. `[inferred]` alone never grounds a build decision.
- **Say the withdrawal plainly.** The owner needs to know which sentence just stopped being true.

---

## Never Correct on a Lagging Signal

A signal that degrades under load is unusable for a correction that is only needed under load.

Codex's instance: a positioning anchor was made self-correcting by reading the live viewport and stepping off the difference. Under main-thread load the viewport's report went stale, "two consecutive equal reads" meant *nothing has updated yet*, and the correction walked the reader to the wrong page. The fix was to use the same reading to **refuse and retry**, never to decide a move — refusing is safe when the reading is wrong; acting is not.

Generalised: any live reading (a progress report, a layout measurement, a sync state) is fine as *metadata* and dangerous as a *verdict*. Before building a correction on one, ask whether the signal is trustworthy in exactly the condition that makes the correction necessary. If not, gate on it; do not steer by it.

---

## Questioning Someone Else's Advice

If a different session, a different model, or a different person gives architectural advice that conflicts with what's in the directive:

1. Surface the conflict explicitly — don't silently pick one
2. Understand the reasoning behind both positions
3. Consider whether the conflicting advice has access to context the current directive doesn't reflect (e.g., implementation experience from actually building it)
4. Make a deliberate decision and update the directive

In practice: Claude Code sessions will sometimes implement things differently than planned directives specify. The right response is not to update the directive to match the code — it's to understand why Claude Code chose differently, decide whether that choice is correct, and then update whichever one is wrong.

---

## When to Get a Second Opinion

For significant architectural decisions — especially those that are expensive to reverse — it is worth asking multiple sessions independently, without sharing the first session's reasoning upfront. If two independent sessions reach the same conclusion, you can be more confident. If they diverge, surface both arguments and decide deliberately.

More capable models (e.g., Opus vs Sonnet) tend to reason more carefully about long-term architectural consequences. For high-stakes decisions, a more capable model is worth the cost.

The key discipline: when you get a second opinion, engage with the reasoning, not just the conclusion. "Opus said to use ReadiumNavigator" is useless. Understanding why Opus said it — and whether that reasoning applies to your specific constraints — is what matters.
