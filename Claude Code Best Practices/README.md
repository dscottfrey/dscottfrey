# Claude Code Best Practices — Starter Kit

A portable playbook for planning and building software projects with Claude Code. Distilled from real project experience, not theory.

**Revised 2026-09-04** against four months of the Codex iOS project (2026-05 → 2026-09): three TestFlight uploads, a dozen testers, ~8,000 lines of HANDOFF, eighty memory files. Every file below was re-read against what actually happened and rewritten where the project proved the kit wrong or incomplete. Sections that changed are dated in place.

**Revised 2026-09-04, Icarus** — in parallel, against four months of the Icarus macOS project (2026-05-19 → 2026-09): a single-customer lab instrument that records projector-lamp degradation over 90-day runs, five notarized releases, one real power loss, one real five-day dataset with a wrong number in it, forty memory files. Where the two projects agree the kit says so once; where they differ (machine topology, how state is held, what "blank" means for a chart) both are recorded. Sections carry the project name beside the date so the two revisions can be merged at the kit's home.

---

## The Projects Behind the Examples

*Added 2026-09-04, Icarus.* The rules in this kit are written to stand on their own. The worked examples are not: they name the project, the date and the quote that paid for each rule, because a rule without its incident gets argued away. A session reading this kit fresh has no other source for what these projects are, so here they are, once.

**Codex** (iOS, 2026-05 → ): an ebook reader for epub files, with a Metal page-curl animation photographed from a Readium web view. Directed by a non-developer owner who cannot read Swift, built entirely through Claude Code, tested by the owner on three devices and by about a dozen friends over TestFlight. Three uploads by September 2026. Its lessons are about testers, logs, a night-time reading surface, and a director who supplies taste and the only ground truth. Marked *(learned on Codex)*.

**Icarus** (macOS, 2026-05-19 → ): a single-window lab instrument that drives six projectors through test screens and records their light output from sensors inside integrating spheres, for runs of up to 90 days, so a lab can measure lamp degradation. One customer (the lab), one machine in the lab, no store, no testers; the same owner directs it and relays the lab's words. Five notarized releases, one real power loss, one real five-day dataset with a wrong number in it. Its lessons are about numbers people act on, hardware nobody watches, data that must survive, and a customer behind the owner. Marked *(learned on Icarus)* or *Revised 2026-09-04, Icarus*.

Both are Apple-platform projects directed by the same person from the same two Macs. Where the two projects disagree, the text says which said what.

---

## What Is This

A set of documents and templates that capture how to set up, plan, and run a Claude Code project well. The goal is to not re-learn these lessons on every new project.

This kit is not a tutorial on Claude Code itself. It assumes you know the basics. It is a collection of *patterns* — ways of working that have proven effective — and, since the revision, of *laws*: rules that were paid for at least twice on a real project and carry the date and the quote that made them.

---

## What Is Here

```
Claude Code Best Practices/
├── README.md                       ← you are here
├── prompt.txt                      ← paste this to start a build session (RESUME-first ritual)
│
├── 01_PLANNING_WORKFLOW.md         ← one repo, one terminal; the three tiers of state (RESUME / HANDOFF / the board); memory in the repo; the Icarus variants
├── 02_DEVELOPMENT_PHILOSOPHY.md    ← code quality principles, quantitative integrity, settings, UX laws, design for nobody watching, engine/UI boundary, build identity, signing
├── 03_DEPENDENCY_FRAMEWORK.md      ← how to evaluate and justify external libraries, with the Readium and Yoctopuce worked examples (hardware is a dependency too)
├── 04_DIRECTIVE_WRITING.md         ← how to write directives; rulings, laws, incidents of record, addenda, the manual as a design test, drift audited as a report
├── 05_ARCHITECTURE_DECISIONS.md    ← record what was rejected; triggers that fired (and premises that moved); refuse at the chokepoint; never mutate the only copy
├── 06_SWIFT_SWIFTUI_IDIOMS.md      ← platform rules for Swift/SwiftUI, the audit, SwiftData without CloudKit, macOS notes, SwiftLint
├── 07_TESTING_AND_DIAGNOSTICS.md   ← what the assistant can verify (including the data on disk), the test round, diagnosis, diagnostics that ship, the findings report
├── 08_WORKING_WITH_THE_OWNER.md    ← session discipline for a non-developer director — pacing, asks, denials, verify-from-disk, and the customer behind the owner
│
├── HANDOFF.md                      ← running log of future additions and open threads for the kit itself
│
└── TEMPLATES/
    ├── CLAUDE_BUILD.md               ← template for the project-root CLAUDE.md (the one Claude Code reads)
    ├── CLAUDE_PLANNING.md            ← historical: the separate-planning-workspace variant
    ├── RESUME.md                     ← the START HERE file — habits first, then dated sections newest first; decisions owed; remind-on-resume
    ├── RELEASE_CHECKLIST.md          ← project settings audit, archive checks, TestFlight steps, and (§F) the macOS Developer ID / notarization order
    ├── RELEASE_NOTES.md              ← NEW (Icarus): the running customer-facing record — "nothing goes in here that isn't true yet", versioning rules
    ├── FINDINGS_REPORT.md            ← NEW (Icarus): the shape of a report to the customer about their own data, from the instrument's own files
    ├── MODULE_DIRECTIVE.md           ← template for a module directive (rulings, laws with incident of record, superseded rules, lessons inherited)
    ├── ADDENDUM.md                   ← template for an experimental-branch addendum
    ├── BUILD_NUMBER_AUTOMATION.md    ← reference script + About-screen code for auto-incrementing build IDs
    ├── DEVELOPMENT_SIGNING.md        ← reference procedure for long-lived dev signing (self-signed fallback; paid team / Developer ID is primary)
    └── link-claude-memory.sh         ← symlinks the assistant's memory into the repo so two machines share it
```

## How To Use This Kit

**Starting a new project:**

1. Create the repo and the Xcode project. Copy `TEMPLATES/CLAUDE_BUILD.md` → `CLAUDE.md` in the project root and fill it in.
2. Create `Docs/`. Copy `TEMPLATES/MODULE_DIRECTIVE.md` for each module and fill them in. Write `Docs/00_OVERALL_DIRECTIVE.md` from `02` and `03`.
3. Copy `TEMPLATES/RESUME.md` → `Docs/RESUME.md`. It is the first thing every session reads.
4. Run `TEMPLATES/link-claude-memory.sh` (edited for the project) so memory lives in the repo.
5. Install the build-identifier system (`TEMPLATES/BUILD_NUMBER_AUTOMATION.md`) **now, not later** — Codex skipped it and shipped an archive with the previous upload's build number.
6. Do the project settings audit in `TEMPLATES/RELEASE_CHECKLIST.md` on day one: deployment target, signing, what the synchronized group ships.

**Starting a build session:**
Paste `prompt.txt` into the Claude Code terminal. It reads RESUME, then HANDOFF, then the module directive, and checks whether the thing it is about to build already exists.

**Before handing the owner a build:**
Read `07_TESTING_AND_DIAGNOSTICS.md` → "The Test Round".

**Before a TestFlight upload:**
Follow `TEMPLATES/RELEASE_CHECKLIST.md` top to bottom.

**Before a macOS build goes to a customer (Developer ID, notarized):** *(Revised 2026-09-04, Icarus)*
`TEMPLATES/RELEASE_CHECKLIST.md` §F, in order — commit first, bump, close the release notes, write the customer's notes, then build. Keep `TEMPLATES/RELEASE_NOTES.md` as the running record.

**When the app's numbers are acted on** — an instrument, a ledger, a timer: *(Revised 2026-09-04, Icarus)*
Read `02_DEVELOPMENT_PHILOSOPHY.md` "Quantitative Integrity Outranks Convenience" before writing the first number to a file, and put its bullet above Occam's Razor in the project `CLAUDE.md`.

**When something runs unattended:** *(Revised 2026-09-04, Icarus)*
`02` "Design for Nobody Watching", and `07` "What Icarus adds for an unattended instrument".

**When a real run exposes a defect in the customer's data:** *(Revised 2026-09-04, Icarus)*
Write the customer the report in `TEMPLATES/FINDINGS_REPORT.md`; write the handoff separately; send the report.

**When you're about to add a library:**
Read `03_DEPENDENCY_FRAMEWORK.md` first.

**When writing a new directive:**
Read `04_DIRECTIVE_WRITING.md` first.

**When starting a new Swift/SwiftUI project:**
Read `06_SWIFT_SWIFTUI_IDIOMS.md`. Do the freshness check at the top (last run 2026-05-04).

**When the owner is not a developer:**
`08_WORKING_WITH_THE_OWNER.md` is the contract. Read it before the first session and again after the first correction.

**When you spot something the kit should eventually cover but isn't ready to write up yet:**
Add it to `HANDOFF.md` so it isn't lost.

---

*This kit was assembled from the Codex iOS project (2025–2026) and revised against it on 2026-09-04, and against the Icarus macOS project on the same date. Update it as new patterns emerge.*
