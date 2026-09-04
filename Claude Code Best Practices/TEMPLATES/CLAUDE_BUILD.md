# [Project Name] — Build Context

## What This File Is

This is the build-workspace `CLAUDE.md` — the file Claude Code reads at the start of every terminal session. It orients the AI assistant to the codebase, the development philosophy, and the module being worked on.

This file lives in the Xcode project root (or equivalent project root). It is not the same as the planning workspace `CLAUDE.md`.

---

## Project Overview

**[Project Name]** is [one sentence describing what the app does and who it is for].

Platform: [iOS/iPadOS / macOS / etc.]  
Minimum target: [e.g., iOS 17]  
Language: [Swift / SwiftUI / etc.]  
Persistence: [SwiftData / CoreData / etc.]  
Key frameworks: [e.g., WKWebView, CloudKit, UIKit]  
External dependencies: [None / list them]

---

## Where to Find the Spec

All module specifications live in `Docs/`:

```
Docs/
├── 00_OVERALL_DIRECTIVE.md    ← read this first, every session
├── 01_[MODULE].md
├── 02_[MODULE].md
└── ...
```

**Before writing any code for a module, read the relevant directive.** The directive is the source of truth. If the directive and the code conflict, one of them is wrong — do not silently pick one. Surface the conflict.

---

## Development Philosophy

These apply to every line of code in this project. They are not aspirational — they are requirements. Each is the project-local restatement of a section in `02_DEVELOPMENT_PHILOSOPHY.md`; when a section is added there, its bullet is added here in the same edit. *(Order is deliberate: the first bullet outranks the second where they conflict — Revised 2026-09-04, Icarus.)*

**Quantitative integrity outranks convenience:** Every number the app shows, records or sends is accurate to the stated precision, or it is not presented — an approximate number will be believed. One quantity, one definition. A count is not a measurement. A reading not taken is an empty cell, never a zero. Derived values read from the accurate source. Anything that can drift is measured against a fixed origin, never accumulated. State the precision and honour it, including in labels. Acceptance test: every number the user can see must be reproducible by hand from the data. Changing one consumer of a quantity is never the whole job. [Remove or scale down only for an app whose numbers nobody acts on, and say so here.]

**Occam's Razor:** When there are two ways to solve a problem, choose the simpler one. If Apple's SDK already does something, use it. Avoid "future-proofing" that adds complexity now for benefits that may never materialize. The simplest thing that works must still be true (see above), and unasked-for capability is not simple.

**Comments are part of the deliverable:**
- Every file begins with a header comment: what this file is, why it exists, how it fits into the module.
- Every function has a plain-English comment before it: what it does, what goes in, what comes out.
- Any non-obvious line or block gets an inline comment.
- When a specific approach was chosen over an alternative, a comment explains why.
- Use `// MARK: - Section Name` to divide long files.

**Document the journey, not just the destination:** If a working solution was reached after several attempts, the comment must capture what was tried and why it didn't work, what the working approach is and *why* it works, and any non-obvious constraint that made earlier attempts fail. Say explicitly: *"This approach was chosen because [X]. Earlier attempts using [Y] failed because [Z]. Do not change this without understanding that constraint."*

**One file, one job:** No file should do more than one thing. ~200 lines is a signal to break it up. Views don't contain business logic. Models don't contain UI code.

**Work with the platform:** If achieving a behaviour requires overriding or working around a standard platform component in a non-trivial way, flag it before writing the code: *"This approach would require working against how [framework] handles [X]. Here's what the standard behaviour looks like, and here's what it would take to override it. Given the simplicity principle, I'd recommend accepting the standard behaviour. Want to proceed anyway?"*

**Every tunable value has a settings home:** Nothing is hardcoded without a conscious decision. Every value a user might reasonably want to adjust gets a setting. Every setting has a written scope (synced / per device / app-level / per run) that follows what the value describes. A constant with a `// TODO: settings home` comment is the failure this rule prevents.

**Every build is identifiable:** Every build produces a unique, automatically-generated build identifier visible in an About screen, and writes a one-line stamp carrying the git SHA to the log at launch. Build numbers are set by automated build phases, never maintained by hand. See `Scripts/generate_build_info.sh` and `Scripts/bump_built_info_plist.sh`, plus their two corresponding Run Script build phases (one before Compile Sources, one as the last phase). The stamp is the assistant's to check in every log, never the owner's to report. The stamp detects a dirty tree; it cannot prevent one — **when the owner says build, notarize, archive or distribute, say COMMIT FIRST before anything else**, and read the About panel back (no `+`) before a build leaves the machine. Two different binaries never share a version number; the version bumps once per shipped build. The upload or hand-off itself is a hand step and is never automated. Reference: `02_DEVELOPMENT_PHILOSOPHY.md` "Every Build Is Identifiable" and `TEMPLATES/BUILD_NUMBER_AUTOMATION.md` in the Best Practices kit.

**Development signing doesn't expire:** Local development builds never use Xcode's auto-provisioned Personal Team certificate. This project signs via [Path 1: automatic signing against the paid team `DEVELOPMENT_TEAM = <team id>` — on macOS outside the App Store, the Developer ID Application identity for every build, Hardened Runtime on / Path 2: a 10-year self-signed certificate per `TEMPLATES/DEVELOPMENT_SIGNING.md`, with the switch to Path 1 recorded as a card for the day the membership activates]. Reference: `02_DEVELOPMENT_PHILOSOPHY.md` "Development Signing Doesn't Expire".

**Color is never the sole signal:** Any information conveyed by color must also be conveyed by at least one other channel — text, an icon or shape, position, or some other non-color cue. Color is permitted as reinforcement of meaning, never as the sole carrier. When implementing a UI element where color is the obvious way to convey state, pause and ask: "Is the color carrying information that nothing else is carrying?" If yes, add a second channel before shipping. Exceptions require explicit owner approval recorded in the relevant module directive. [If the owner de-scopes this for a known single-user audience, as Icarus did on 2026-06-17, strike this bullet through here with the date and reason rather than deleting it — the override is a decision and leaves a trail.]

**Design for nobody watching:** For anything that runs unattended, the alarm path exists from launch, not after a human resumes; a one-shot dialog or a grey card on one tab is never the only signal — a fault repeats (banner on every tab, sound, message) until a person acts; a status never claims health it cannot prove ("Running" only while a live process drives it); rehearsals are possible without the real outage and every rehearsal artefact is marked SIMULATED. An idle state that keeps something expensive running must justify what it buys. [Remove only if nothing in this app runs unattended.]

**The Engine does not move the pixels:** The Engine (measuring, data flow, recording, persistence, recovery) and the UI (everything the user sees and drives) are the two halves, named in `Docs/`. An Engine change leaves every existing pixel where it was; if a UI change is genuinely forced, stop and ask first. Adding something new is allowed and is still listed in the handoff. Every Engine handoff says "No UI changes" or exactly what changed on screen. Reuse a shared component ("include") by parameterizing it; never build a lookalike copy. One piece of state behind any control shown in two places.

**Every wait has a timeout and a fallback:** Any `await`, poll or readiness gate the user's screen sits behind is paired at write time with a deadline and a visible fallback (error, retry, or an honest degraded result). A bare await on library code is a bug; hunt for them in review like force-unwraps.

**Never silently lose the user's content:** When something cannot be shown correctly, show it by another route or refuse visibly (a turn that does not happen, a blank, an honest error). Never a silent skip, never content cut off and presented as complete. Any fix described as "loses a few lines" is the unacceptable branch.

**A rule about what is recorded never decides what is displayed:** Every guard names its consumer. A guard protecting what is *saved* may not suppress what is *shown*; the display may be an honest estimate, the record must never be wrong. Anything suppressed at bake time (snapshot, render, export) is suppressed permanently.

**Resources ship regardless of `#if DEBUG`:** Every file under the app's synchronized folder joins the target. Nothing copyrighted or third-party lives there — samples and fixtures go in a gitignored repo-root folder. Before any upload, inspect the archive with `find`; never reason about it.

**Three ways, all of them right:** Nothing is reachable only by an unhinted gesture; a gesture may be a shortcut, never the only path. A control that must be learned (`•••`, swipe-to-reveal) is not an affordance — prefer visible, self-describing controls, and answer mis-tap risk with a confirmation, not by hiding. Hiding a whole layer behind one reveal (a reader's chrome) is legitimate; hiding one verb inside a surface that looks complete is not. Never hide what was explicitly asked for: a search shows everything that matches, whatever its state.

**Never ask a question whose answer changes nothing:** Ask when there is a real choice; tell when there is only news; say nothing when there is not even news. During the testing stage, prefer a sentence on the glass to a quiet default, and log the same fact.

**The paired intuition:** A control is not finished until its failure is intuitive — the user's first instinctive reaction to a wrong result must *be* the fix, never a setting to find or a gesture to learn.

**Scrollable panels must look scrollable:** Size every sheet or panel to show all its content; if it must scroll, the presented height cuts visibly through a row, never cleanly at a section boundary. Applies to debug UI too.

**The dark adaptation law:** No area escapes the theme — a white flash at night is a functional failure. Dark is a designed theme, never an inversion and never pure black (OLED phones are the majority dark surface). Paint from the app's theme object, never from the device colour scheme or a bare material; dark-mode users commonly run light devices, so test theme work with the device in light mode. Reduce Motion is a first-class path, not a fallback.

**Swift/SwiftUI projects:** Also read `Docs/06_SWIFT_SWIFTUI_IDIOMS.md` (copied into the project's `Docs/` folder from the Best Practices kit at project setup time). It contains platform-specific rules — modern API discipline, observation patterns, view composition, and common AI-generated-code anti-patterns — that complement the general principles above. Remove this bullet entirely if the project is not Swift/SwiftUI. *(Optional, Revised 2026-09-04, Icarus: Icarus also keeps a condensed always/never cheat-sheet of those rules in this file under "Swift / SwiftUI — Quick Rules", so the critical ones are seen at session start without fetching the long file. If you add one, give it the same drift discipline as this section: when a rule changes in the idioms file, the cheat-sheet changes in the same edit. It held on Icarus through a dozen rule changes.)*

---

## Dependency Policy

Zero external dependencies is the goal state. Before reaching for a library, answer:
1. Does Apple's SDK already do this?
2. Can we write a focused custom implementation?
3. What exactly do we need from this library?

Any dependency in the project is documented in `Docs/00_OVERALL_DIRECTIVE.md` under the Dependencies section. Do not add new dependencies without recording them there with full rationale, version pin, what is used, what is NOT used, and trigger to revisit.

---

## Before You Write Any Code

1. Read `Docs/00_OVERALL_DIRECTIVE.md`
2. Read the directive for the module you are working on
3. Summarize what you are going to build and in what order — give the owner a chance to redirect before work begins
4. If anything in the directive is ambiguous or conflicting, surface it before starting

---

## Anti-Goals

[List the explicit things this project does NOT build, copied from 00_OVERALL_DIRECTIVE.md. Examples:]

- No [feature X]
- No [feature Y]
- No [feature Z]

These are decisions, not absences of decisions. Do not add features not in the directive without explicit instruction.

---

## Session Discipline

- **Do not invent solutions not specified in the directive.** If the directive doesn't specify how something should work, ask before implementing.
- **Do not update the directive to match the code** without a deliberate decision that the code is actually right.
- **Explain technical decisions in plain English.** The project owner may not be a developer. Jargon is explained in context, not assumed.
- **Surface conflicts explicitly.** If a different approach seems better than what's specified, say so — with reasoning — rather than silently implementing something different.
- **Check whether it exists before building it.** Grep for the type or the phrase; read the directive, not the card; check for zero callers ("built and unreachable" is commoner than "unbuilt"). On Codex, nine of twenty-one cards closed in one day needed no building.
- **Read the code; never ask the owner whether something is done.** The owner cannot read the language and a card's status is stale prose. Bring a finding with a file and line, not a question. The only fact that is genuinely the owner's is whether a thing works on a device.
- **The assistant may not be able to compile.** In a sandboxed session `xcodebuild` can fail; "done" from source alone is a claim about code, not the app. Type-check what you can, run pure logic as a scratch probe, and say plainly what was and was not verified. See `07_TESTING_AND_DIAGNOSTICS.md`.
- **One build in flight at a time.** After handing the owner a build, freeze the tree — no commits, no edits, no revised instructions — until the full test report is in. Each hand-off names what to check, what is known-broken (do not report), and what is genuinely open. See `07_TESTING_AND_DIAGNOSTICS.md`.
- **Code exports its memory.** Anything deliberately unfinished carries `// OWED:` / `// WHY:` / `// TRIGGER:` written for the owner (what a user would notice), and the harvest script regenerates `Docs/OWED.md`. Bare `TODO`s are invisible.
- **Never delete by a computed address.** A range located by a non-unique string once emptied a whole file and the commit recorded it. Assert the match count, print the range, then delete — and never chain a delete with a commit.
- **Size work by shape and risk, never in hours or days.** Time estimates run an order of magnitude high.
- **Verify from disk yourself.** *(Revised 2026-09-04, Icarus.)* Anything file- or database-observable — data files, logs, the SQLite store — the assistant reads and reports. Never assign the owner a file check the assistant can do. Ask the owner only for what the assistant genuinely cannot observe: the screen, the hardware, a build.
- **Flag a guess as a guess, out loud, every time.** *(Revised 2026-09-04, Icarus.)* "I'm guessing…" or "unverified — we'd confirm by…" before any diagnosis not read from source or measured. A confident wrong diagnosis once sent the owner rewiring hardware that was fine.
- **"Implemented" is not "verified", and "exists" is not "wired".** *(Revised 2026-09-04, Icarus.)* A handoff states what is wired and what has been proven on the real thing; a file that is called from nowhere is not a feature. Check for zero callers before claiming a capability.
- **Directive drift is audited as a report, never fixed in passing.** *(Revised 2026-09-04, Icarus.)* When code and directive disagree, table the divergence (file:line ↔ section, what each says, which looks authoritative) and let the owner rule. Either side can be the stale one. See `04_DIRECTIVE_WRITING.md`.
- **Say when the shipped source exists in only one place.** *(Revised 2026-09-04, Icarus.)* An unpushed branch that builds have shipped from is stated in every handoff until it is pushed.

---

## Owner Working Preferences

How this owner wants sessions to run. These are owner-specific examples taken from the Codex owner's global `CLAUDE.md`; edit or remove for the actual project owner. They exist because a non-developer director's attention is the scarce resource, and each of these was written after it was wasted.

- **Never use multiple-choice popups or the `AskUserQuestion` tool.** Ask inline as plain text. [Codex: the owner cannot touch-type and watches his hands, so a popup wipes whatever he is typing and can register an answer he never saw.]
- **One command at a time.** Give a single command, stop, wait for the output. Do not batch commands or narrate between them.
- **Short messages, ask on top.** The question or action goes in the first line; one ask per message. Essays go in the repo; the chat gets the conclusion. Chattiness burns the context window — *"compacting is a sign we have gone too long."*
- **When a permission prompt is denied, always interrupt and confirm.** Adjacent keys and focus clicks make accidental denials common. On any denial: ask whether it was the wrong key or a real question; say what the call would have done; say what is now half-done if it is skipped; offer to retry. A second denial after a clear explanation is a genuine no.
- **After any sensitive approval, audit for a new standing permission.** "Always allow" sits next to "allow." Check the settings files for a new rule and say so if one appeared.
- **State in one line what is about to be approved** before any call that will prompt, so the prompt is never the first time the owner sees the request. Prefer one bulk call over N individual ones.
- **Discussion is not instruction.** The owner thinks out loud; answer with reasoning and record findings, but never move a priority, tier or scope he did not ask to move.
- **Strict step pacing when the owner numbers steps.** Do exactly one, stop, wait. "Add a print" means add one print line.
- **Ask for a picture rather than reasoning about anything the owner can see**; name exactly what to capture. Pictures are the owner's side; logs are the assistant's.
- **If anything the owner typed does not make sense as a real word in context, ask** — autocorrect swaps words on send. A plain misspelling is not a reason to ask.
- **Pushing is the owner's**; commit locally and say once when the branch is push-ready. [Write the machine topology here in one line — which machines share the repo, which receive built apps — because "pull" and "push" mean different things on different topologies. Codex: one working copy, never say "pull". Icarus: desktop and laptop share the repo by push/pull; the lab Mac gets notarized builds and has no repo. *(Revised 2026-09-04, Icarus.)*]
- **Prefer the tool that does not prompt.** *(Revised 2026-09-04, Icarus.)* Edit and Write apply silently in the owner's usual mode; every shell call raises a permission prompt, and a prompt is a chance to lose an edit — one was lost to a mis-keyed prompt on 2026-07-31. Shell is for shell work (grep, git, running a parser), not for splicing files.
- **Enumerate open questions as a numbered list and STOP.** *(Revised 2026-09-04, Icarus.)* The terminal surfaces the owner's answers one at a time; racing on to the next block before an answer arrives loses the thread. Especially before anything that changes a schema or an endurance path.
- **When the owner says build, notarize, archive, distribute, or "put it on the lab" — say COMMIT FIRST, unprompted.** *(Revised 2026-09-04, Icarus.)* A dirty-tree build is untraceable and it is the one that always ends up staying.
- **A memory that says "remind me on resume" is raised at the start of the next session, unasked**, and deleted when the owner confirms it is done. *(Revised 2026-09-04, Icarus.)*

---

## Owner Accessibility Notes

Accessibility requirements driven by the project owner. These apply to both how Claude Code communicates with the owner during terminal sessions *and* to color choices implemented in the app itself.

The owner has Protanomaly. When providing color-coded information, do not rely on the distinction between Purple/Blue, Green/Brown, or Orange/Green. Use high-contrast labels, distinct icons, or textures instead of color alone.

The same pairs must also be avoided when implementing or proposing colors for the app itself — brand palette, status indicators, chart series, accents, anything visible. The owner reviews every design and uses every build, so a color scheme that visually collapses these pairs for the owner makes both daily use and design review harder. The owner's apps are primarily for the owner's own use; broader accessibility is also a goal but the owner's specific needs take priority when they conflict.

[This is in addition to, not a replacement for, the universal redundancy rule in the development philosophy section above (see "Color Is Never the Sole Signal") — both apply. Edit or remove the owner-specific guidance above based on the actual project owner.]

---

*Build context last updated: [Month Year] — template revised 2026-09-04 from the Codex project, and again 2026-09-04 from the Icarus project (three new philosophy bullets, session-discipline and owner-preference additions, the overrides convention, the topology line).*
