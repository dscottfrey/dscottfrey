# Handoff — Future Additions and Open Threads

A running log of things to capture, revisit, or decide for the Best Practices kit. Mirrors the Handoff Notes pattern from `05_ARCHITECTURE_DECISIONS.md` — items here are deliberately deferred, not forgotten.

When an item is acted on, mark it ✅ with a brief note about where it landed (which file, which section) and the date. Do not delete resolved items — the history is part of why we trust the kit.

---

## Candidate Topics — Not Yet Covered

### ✅ Testing Strategy — resolved 2026-09-04, `07_TESTING_AND_DIAGNOSTICS.md`
The trigger fired: Codex shipped to a dozen testers and a regression slipped through more than once. The kit is no longer silent on testing. Open questions: what level of test coverage is expected; unit vs integration vs UI; how to spec testability in directives; whether Claude Code should write tests by default or only when asked; how to handle the "tests pass but feature is wrong" failure mode.

*Trigger to capture:* first project that ships to real users, or first time a regression slips through because there were no tests.

### ✅ Error Handling and Logging Conventions — resolved 2026-09-04, `07_TESTING_AND_DIAGNOSTICS.md` "Diagnostics That Ship"
Trigger fired on Codex in August 2026; the log file became the primary debugging instrument. Was: no guidance on error surface (Result vs throws vs Optional), what gets logged and at what level, how errors are presented to users, or how to structure logs so future debugging sessions can use them.

*Trigger to capture:* first project where logs become important to debugging.

### Security and Secrets Handling
Nothing on API keys, tokens, environment variables, keychain usage, what never goes in git, how to handle credentials in CI. Adjacent: the kit forbids hardcoded values for tunables but doesn't say how to handle hardcoded secrets.

*Trigger to capture:* first project that integrates an external service requiring credentials.

### Performance Profiling Discipline
The kit specifies performance *requirements* go in directives (`04_DIRECTIVE_WRITING.md §5`) but doesn't cover when to profile, what tools, how to record baselines, when "fast enough" wins over further optimization.

### Git and Commit Practices
Root files exist (`git-branching-guide.md`, `committ-files-in-xcode.md`, `collaborating.md`, `Xcode - GitHub setup.md`) but none are pulled into the kit. Decide: fold relevant pieces in as `06_GIT_WORKFLOW.md`, or keep git/setup separate from the directives kit.

*Note:* mining these requires cross-folder edit permission per current rules.

### ✅ Session Post-Mortem Pattern — resolved 2026-09-04, `01_PLANNING_WORKFLOW.md` "Session End Ritual"
Codex's answer was three-fold: a dated section in RESUME (what to do next), a dated section in HANDOFF (why), and a memory file per lesson (`feedback_*` / `project_*`, in-repo). Was: no standing pattern for capturing what was learned in a session — only the directive update itself. A lightweight post-mortem ("what surprised me, what would I tell future-me") could be the source material that feeds back into this kit over time.

*Trigger to capture:* once we have a few cycles of real evolution to draw from.

---

## Meta — Kit-Level Questions

### iOS/Xcode-Specific vs Platform-Agnostic
The kit is positioned as portable but several examples and code skeletons are Swift/iOS-flavored. Decide: explicitly scope the kit to Apple platforms, generalize the examples, or add a small "platform appendix" pattern.

### Cross-Reference Discipline Inside the Kit Itself
The kit teaches cross-referencing as a directive practice but the kit's own files don't cross-reference each other. Worth adding "see `04_DIRECTIVE_WRITING.md §X`" links where concepts overlap (the Handoff Notes pattern is mentioned in both `01` and `05`, for instance).

---

## Active Threads

### ✅ Broader Accessibility Coverage — partly resolved 2026-09-04, `02_DEVELOPMENT_PHILOSOPHY.md`
Added the Dark Adaptation Law, Reduce Motion as a first-class request, Dynamic Type scoped to chrome, and (in `06`) VoiceOver on custom controls as an audit finding. Still uncaptured: contrast ratios, touch-target sizes (Codex measured a fingertip's reported point wandering ~15 pt and widened its edge strips to 72 pt — HANDOFF §24.1 — worth a rule), keyboard/Switch Control. Promote to `06_ACCESSIBILITY.md` when those land. Was: "Color Is Never the Sole Signal" in `02_DEVELOPMENT_PHILOSOPHY.md` is the first accessibility principle in the kit. Other principles worth capturing eventually: VoiceOver / screen reader support requirements; dynamic type and text-size scaling; minimum contrast ratios; reduced-motion preference; minimum touch target sizes; keyboard / Switch Control navigation; haptic feedback redundancy. May warrant promotion to a dedicated `06_ACCESSIBILITY.md` once there are 4+ principles.

*Trigger to expand:* next time a project encounters a real accessibility need beyond color, or the owner wants to spec accessibility for an app.

### Build Template Summary Drift
`TEMPLATES/CLAUDE_BUILD.md` includes a condensed summary of the principles from `02_DEVELOPMENT_PHILOSOPHY.md`. Twice now (Every Build Is Identifiable, Color Is Never the Sole Signal) a new principle was added to `02` and the build template summary was missed on the first pass — discipline since adopted: every time a section is added to `02`, the corresponding bullet in `CLAUDE_BUILD.md`'s "Development Philosophy" section is added in the same edit. Held cleanly when "Development Signing Doesn't Expire" was added on 2026-05-04.

*Trigger to resolve:* if the discipline fails again, consider mechanical alternatives (e.g., have the build template `include` from `02`, or generate it).

### Pattern: External Sources Need Freshness Checks
The kit now incorporates content from at least one external authoritative source that evolves (Paul Hudson's `SwiftAgents`, mirrored in `06_SWIFT_SWIFTUI_IDIOMS.md`). The freshness mechanism baked into `06` — sync date at top, "before relying on this for a new project, fetch the upstream and reconcile" instructions, "Local Divergences" section — should generalise into a kit-wide pattern when we incorporate from any other evolving source. If/when a third such incorporation happens (Apple HIG digest, third-party Swift package conventions, accessibility guidelines digest, etc.), promote this from "the way `06` happens to do it" to a documented kit pattern in `04_DIRECTIVE_WRITING.md` or its own short file.

*Trigger to resolve:* a third incorporation from an external evolving source.

### ✅ SwiftLint Adoption Decision — resolved 2026-09-04, Icarus
Icarus adopted SwiftLint on its first day (condition (c): the owner wanted a build-time gate). The configuration, the Run Script phase, the Homebrew `PATH` gotcha and the same-line-rationale rule for inline disables are recorded in `06`'s "Local Divergences" and live in full in Icarus's `Docs/99_SWIFT_SWIFTUI_IDIOMS.md`, liftable verbatim. Was: `06_SWIFT_SWIFTUI_IDIOMS.md` deliberately omits SwiftLint guidance — it is not currently in use, and most of what SwiftLint catches is covered by the existing rules. SwiftLint becomes worth adopting when (a) Claude Code starts producing inconsistent Swift code that the kit's rules don't catch, or (b) a multi-contributor project starts where enforcement is more important than just guidance, or (c) the owner specifically wants a build-time gate on style.

*Still open:* a `TEMPLATES/` file for it, if a third project wants one; until then the Icarus file is the reference.

### ✅ Switch From Self-Signed to Real Developer ID — resolved 2026-09-04
The owner has had a paid membership since 2026-05-11; Codex signs automatically with the real team. `02` now leads with the paid-team path and keeps self-signing as the fallback; the template's status header says so and its procedure is untouched. Was: `TEMPLATES/DEVELOPMENT_SIGNING.md` and the "Development Signing Doesn't Expire" section in `02_DEVELOPMENT_PHILOSOPHY.md` currently describe the self-signed-cert approach. When the project owner has a paid Apple Developer Program membership and a Developer ID Application certificate, both need revisions:

- The principle in `02` stays the same; only the implementation guidance updates.
- The template's "Status of This Reference" section gets replaced/removed, the procedure switches from Keychain-Assistant cert creation to "use your Developer ID Application identity," and the Debug-only library-validation entitlements exception can probably be removed entirely (since Apple-issued certs have a real `TeamIdentifier` that satisfies library validation natively).
- The release-checklist item "switch signing back to Developer ID before archiving" can be reduced to "verify Developer ID is the active identity" or removed if the dev cert and the distribution cert become the same thing.

*Trigger to resolve:* the project owner explicitly tells Claude they have the Developer ID Application certificate and want the kit revised. Until then, self-signing is the right tool.

---

## Resolved

- ✅ **2026-05-04 — Build Number Automation (initial spec).** Added "Every Build Is Identifiable" section to `02_DEVELOPMENT_PHILOSOPHY.md` and reference implementation to `TEMPLATES/BUILD_NUMBER_AUTOMATION.md`. Chose Option B: every build regenerates a `BuildInfo.swift`; Release builds additionally bump `CFBundleVersion` in `Info.plist` for App Store / TestFlight compliance. Initially supported both new-project and retrofit flows.

- ✅ **2026-05-04 — Swift/SwiftUI Idioms (platform layer).** Added `06_SWIFT_SWIFTUI_IDIOMS.md` as the first platform-specific layer of the kit; files 01–05 remain platform-agnostic. Adapted from Paul Hudson's [SwiftAgents](https://github.com/twostraws/SwiftAgents) `AGENTS.md` (which itself derives from his article ["What to fix in AI-generated Swift code"](https://www.hackingwithswift.com/articles/281)). Kit-conformant adaptations: added rationale to most rules, added an "Older Target Adjustments" table for projects not on iOS 26+, added a "Source and Freshness" section pinning the sync date and prescribing a refresh check before each new project's use, added a "Local Divergences From Source" section (omitted: "Senior iOS Engineer" persona framing because it conflicts with the kit's plain-English-to-non-developer audience; omitted: SwiftLint section because not in use; modified: view composition rules to flag community-debate trade-offs rather than assert flat rules). Updated README, build template (added a single conditional pointer bullet rather than replicating ~30 rules inline), and HANDOFF (build-template summary drift discipline held). New active threads queued: source-freshness pattern (meta), SwiftLint adoption decision.

- ✅ **2026-05-04 — Development Signing (self-signed cert).** Added "Development Signing Doesn't Expire" section to `02_DEVELOPMENT_PHILOSOPHY.md`, plus reference implementation at `TEMPLATES/DEVELOPMENT_SIGNING.md`. Captures the rationale (Personal Team certs expire and are silently revoked on Apple infra rotations), the procedure (Keychain Assistant 10-year self-signed cert, Manual signing identity per target, Debug-only entitlements file with `disable-library-validation` to keep XCTest working, Xcode 16 debug-dylib disabled), and the gotchas discovered during real implementation. Updated `CLAUDE_BUILD.md` philosophy summary in the same edit (drift discipline held). New active thread tracks the eventual switch to a real Developer ID Application certificate.

- ✅ **2026-05-04 — Build Number Automation (refined from real implementation).** Original spec was put through a real project setup, which surfaced multiple bugs. Folded the findings back into the kit: switched timestamp format to `YYMMDDhhmm` (10 chars); split the work into two scripts and two Run Script phases (`generate_build_info.sh` before Compile Sources, `bump_built_info_plist.sh` as the last phase); changed Release-mode `CFBundleVersion` mutation to target the *built* `Info.plist` (works for both hand-maintained and `GENERATE_INFOPLIST_FILE = YES` modes, never mutates a committed file); switched `BuildInfo.swift` from gitignored-and-untracked to tracked-as-placeholder (synchronized groups in Xcode 16+ require the file present at build-graph construction time); added the User Script Sandboxing build-setting step; added a "Known Gotchas" section in the template covering quote stripping, About panel name casing with `GENERATE_INFOPLIST_FILE`, `git status` noise tolerance, synchronized-group target membership, and `.gitignore`/`git add` interaction. Updated `02_DEVELOPMENT_PHILOSOPHY.md` and the build template's philosophy summary to match. Reframed the kit so build identification is set up from day one on new projects only — retrofit flow is no longer supported, and `prompt_retrofit_build_number_automation.txt` was removed.

---

- ✅ **2026-09-04 — The Codex revision.** Every kit file re-read against four months of the Codex project (three TestFlight uploads, a dozen testers, ~8,000 lines of project HANDOFF, eighty memory files) and rewritten where the project proved the kit wrong or incomplete. Headlines: `01` moved from two workspaces to one repo and added the three tiers of state (RESUME / HANDOFF / the board) and in-repo memory; `02` gained twelve sections (timeouts, never lose content, record-vs-display, resources ship regardless of `#if DEBUG`, the UX laws, dark adaptation) and rewrote build identity and signing from what actually happened; `03` gained the Readium worked example and the project-skill pattern; `04` gained rulings, laws and the manual-as-design-test; `05` gained the fired trigger, lagging signals and cross-check-when-confident; `06` gained the audit pattern; `07` and `08` are new; `TEMPLATES/` gained RESUME, RELEASE_CHECKLIST and link-claude-memory.sh. Build-template drift discipline held: `CLAUDE_BUILD.md` was resynced in the same pass.

---

## New Threads — 2026-09-04

### How the kit is revised — the round trip
The kit has a home of its own, under version control, outside any project. To revise it: copy it into a project (Codex keeps it in the gitignored `Samples/`), let that project's Claude Code session revise it against what the project learned, then move it back home and commit there. The copy inside a project is a working copy, never the record.

Two projects may revise the kit in the same period (2026-09-04: Codex, and a second project in parallel). Every revised section carries its date and the project it came from, so the two copies can be merged by hand at home — section by section, newest fact wins, both projects' worked examples kept. *Trigger:* the next time two copies come home together, decide whether hand-merging still scales or the kit needs a proper branch-per-project workflow.

### `06` freshness check is overdue
Last synced with upstream 2026-05-04. *Trigger:* before the next new Swift project, per the file's own rule.

### Owner preferences are now in three places — trigger fired 2026-09-04, Icarus
The owner's global `~/.claude/CLAUDE.md`, `08_WORKING_WITH_THE_OWNER.md`, and `TEMPLATES/CLAUDE_BUILD.md`'s "Owner Working Preferences". Decide which is the master; the kit copies should say "see the global file" rather than restate it if they drift. *Trigger:* the first time the three disagree. **They disagreed:** `08` said *"never say pull"* as a flat rule; on Icarus the same owner syncs two development machines by push/pull and the word is load-bearing. Resolved in `08` by making the rule topology-dependent and asking every project `CLAUDE.md` to state its machine topology in one line. The master question is still open; the global file is the owner's and is deny-listed to the assistant, so the kit copies can only ever be restatements.

### Touch-target and fingertip rules
See the accessibility thread above — a measured fact (a reported touch point wanders ~15 pt) that the kit does not yet turn into a rule.

### Platform-agnostic claim is now false for `02`
`02` carries build identity, signing, resources-in-synchronized-groups and the CloudKit schema trap, all Apple-specific. Either scope the kit to Apple platforms honestly or split those into a `02.1_APPLE_PLATFORM.md`. *Trigger:* the first non-Apple project. *(Icarus, 2026-09-04: the kit now spans two Apple platforms — `06` carries iOS rules with a macOS notes section, `RELEASE_CHECKLIST` has an iOS body with a macOS §F. A per-platform appendix pattern is probably the honest shape; still triggered by the first non-Apple project.)*

---

## Resolved — 2026-09-04, Icarus

- ✅ **2026-09-04 — The Icarus revision.** Every kit file re-read against four months of the Icarus macOS project (a single-customer lab instrument on 90-day runs; five notarized releases; one real power loss; one real five-day dataset; forty memory files, nine dated handoffs, a 1,374-line resume file), in parallel with the Codex revision of the same date. Every changed or added section carries *"Revised 2026-09-04, Icarus"* so the two copies can be merged by hand at home. Per file:
  - **`README.md`** — Icarus paragraph in the header; file tree and "How To Use" updated for the two new templates and the four new entry points (macOS ship order, instrument-class apps, unattended systems, findings reports).
  - **`prompt.txt`** — the opening summary now asks for the unpushed-branch and shipped-unproven state and anything RESUME says to raise unprompted; two standing rules appended (verify from disk yourself; say a guess as a guess).
  - **`01_PLANNING_WORKFLOW.md`** — the Icarus variants recorded in place: the rewrite rule failing on RESUME (prepended to 104 KB, with the dated "top block" banner as the fallback); dated per-session handoff files and their recurring section shape; no board; memory *not* in the repo (open question); session-end additions — say where the shipped source lives (five releases from an unpushed branch), list what shipped unproven; two-workspace model confirmed dead by a second project.
  - **`02_DEVELOPMENT_PHILOSOPHY.md`** — three new sections: **Quantitative Integrity Outranks Convenience** (six rules, the five-day-run incident of record, the banner, the caption, the meter log; placed *above* Occam's Razor on purpose; "a blank is only honest when it cannot be mistaken for data"; "guards must measure the real cost"), **Design for Nobody Watching** (the 26-hour stranded run, six rules, the lamp-time tension), **The Engine Does Not Move the Pixels** (the Play-button regression, includes, one state behind two controls, the written glossary). Refinements: Occam's rank and the "I was being clever" knob; Never Lie extended to user-facing strings, directive lines, "implemented vs verified", `SIMULATED` markers; Record-vs-Display gains the third consumer (what makes it *stop*); settings gain *scope*, "one name on screen", and the constants-with-a-TODO failure; Build Identity gains "installed on day one — the stamp is a detector, not a preventer", COMMIT FIRST, About read-back, one bump per build, provenance in the About panel; Signing gains the macOS Developer ID path; Anti-Goals gain the strike-through-with-date and carve-out convention; Color-Is-Never-the-Sole-Signal records the Icarus override and its reason; the Development Model Note points at the Icarus owner rules in `08`.
  - **`03_DEPENDENCY_FRAMEWORK.md`** — Icarus worked example: the record written on day one with the pin still blank ("pin filled?" joins the checklist); the directive's "Lessons Inherited" section as the skill for a small dependency; **hardware is a dependency** and needs the same record plus "what it does that its documentation does not say"; verify against the vendored source at the pinned version.
  - **`04_DIRECTIVE_WRITING.md`** — new section **Drift Runs Both Ways — Audit It as a Report, Never as a Fix** (four stale claims in one file; the owner's read-only-report rule and why; WIRED not EXISTS); rules and anti-goals that fall are struck through, not deleted; laws gain "attach the incident of record" and "placement states precedence"; corrections name the old wording.
  - **`05_ARCHITECTURE_DECISIONS.md`** — trigger pattern's second and third firing (the UPS decision: parked with a trigger that names the wrong inference, fired after the power loss, then the premise moved twice — record the premise; "the mechanism cannot fire" is not "the mechanism is wrong"); new **Refuse at the Chokepoint** (`NSScreen.main`, four sites then a fifth, the escape-hatch corollaries); new **Persistence: Never Mutate the Only Copy** (seven rules from two lost stores); "Not a bug — recorded so nobody fixes it" under Record What Was Rejected.
  - **`06_SWIFT_SWIFTUI_IDIOMS.md`** — what Icarus did with the file (macOS 15 rescoping, four recorded overrides, the standing swiftui-pro rule, the 2026-06-17 audit); the CloudKit-only framing of the SwiftData section corrected as wrong, with a **SwiftData without CloudKit** subsection (explicit store URL, lightweight migration wipes, quadratic relationships → scalar keys + indexes, reconstruction rows with nil relationships, bounded memory, reading the store directly); new **macOS Notes** (nine paid-for platform facts); SwiftLint adoption recorded in Local Divergences.
  - **`07_TESTING_AND_DIAGNOSTICS.md`** — **Tier 0: read what the app wrote to disk** (verify from disk yourself; the SQL-join false alarm); "implemented ≠ verified, exists ≠ wired" in the claim discipline; the fourth pre-test list (**shipped unproven**) and the release-notes rule; **the bench is not the rig** (OS version, a microphone, production cardinality; let the customer yank a cable); test-untethered additions for macOS (debugger zombie, DerivedData login item); **measure before blaming** (the disk-full and −273 °C misdiagnoses, estimates wearing constants' clothing, unconfirmed recollections, dead ends recorded); endurance instruments (symptoms that worsen with uptime, proportionate watchdogs, jetsam); **what Icarus adds for an unattended instrument** (companion log beside the data, a heartbeat as a *file* because Console never shows history, the OS's own `.diag` reports, sensor-level simulators, record the flap); new **The Findings Report** section.
  - **`08_WORKING_WITH_THE_OWNER.md`** — new: enumerate-and-stop; COMMIT FIRST; do not add what was not asked for; "when there is a date, it moves"; **when there is a customer behind the owner** (attribute owner vs lab, the customer's data, measurement decisions are the lab's, a settled position lacking buy-in is not an open question); verify from disk yourself; flag a guess; implemented vs verified; prefer the tool that does not prompt; remind-on-resume. Corrected: **"never say pull" is topology-dependent** — the kit stated it flat and Icarus proved it wrong; every project `CLAUDE.md` states its topology. Note on the Protanomaly line: the owner's needs and the app's audience are two facts.
  - **`TEMPLATES/CLAUDE_BUILD.md`** — three new philosophy bullets in the same edit as their `02` sections (drift discipline held); bullets for settings scope, build identity (COMMIT FIRST, About read-back, one bump per build), the macOS signing path, the override convention on the colour bullet; the optional quick-rules cheat-sheet note; five session-discipline bullets (verify from disk, flag guesses, wired vs exists, drift as a report, unpushed source); five owner-preference bullets (topology line, non-prompting tools, enumerate-and-stop, COMMIT FIRST, remind-on-resume).
  - **`TEMPLATES/RELEASE_CHECKLIST.md`** — new **§F, macOS direct distribution**: the nine steps in the order they must happen, from Icarus's ship checklist and the release that went out as the wrong version.
  - **`TEMPLATES/RELEASE_NOTES.md`** — NEW. The running customer-facing record: "nothing goes in here that isn't true yet", state what the bench cannot prove, lead with what the customer will see, the versioning rules (one bump per build; two binaries never share a version; a compatibility break is not a major).
  - **`TEMPLATES/FINDINGS_REPORT.md`** — NEW. The ten-part shape of a report to the customer about their own data, generalised from the five-day-run report.
  - **`TEMPLATES/RESUME.md`** — "shipped source in one place?" and "shipped but never run" lines; §3a decisions owed by the owner; §3b remind on resume; the dated top-block banner as the fallback when the rewrite rule slips.
  - **`TEMPLATES/MODULE_DIRECTIVE.md`** — incident of record beside a law; a Superseded convention; §3.0 Lessons Inherited.
  - **`TEMPLATES/BUILD_NUMBER_AUTOMATION.md`** — "when it *was* installed on day one": the `+` is a detector, not a preventer; provenance in the About panel.
  - **`TEMPLATES/DEVELOPMENT_SIGNING.md`** — the macOS Developer ID status note; the "will be revised when…" footer closed.
  - **`TEMPLATES/CLAUDE_PLANNING.md`** — the second data point on the two-workspace model.
  - **Unchanged:** `TEMPLATES/ADDENDUM.md`, `TEMPLATES/claude.md` (the upstream copy), `TEMPLATES/link-claude-memory.sh`.

---

## New Threads — 2026-09-04, Icarus

### A host-machine deployment document is owed
Every kit file covers the app; nothing covers the machine it runs on. Icarus's lab Mac filled its disk with a runaway search index (66 GB), ran a language model summarising personal messages on an 8 GB machine that must stay up 90 days, and lacked Full Disk Access for Terminal so `du` under-reported by tens of gigabytes mid-incident. The owner asked for a "Deployment Best Practices" document (2026-07-30): search indexing and Apple Intelligence off, disk headroom checked before a run, the OS's diagnostic reports read after day one, which build is deployed and how to verify it, sync settings, and the machine's own account. Not written on Icarus either. *Trigger:* the next project that ships to a machine the owner does not sit at — or the Icarus document, when it is written, generalised into `TEMPLATES/`.

### Memory not in the repo — did it cost anything?
Icarus is directed from two machines and keeps its forty memory files machine-local, unlike Codex. No session recorded a fact missing on the other machine, so this is a question, not a finding. *Trigger:* the first Icarus session that notices a memory it wrote on the other machine is absent — then run `link-claude-memory.sh` there and record the answer here.

### The RESUME rewrite rule failed on one of two projects
Recorded in `01`. *Trigger:* if it fails on a third, the template's "rewritten, not appended" instruction is wrong and the dated-banner fallback becomes the rule.

### Instrument-class apps — is Quantitative Integrity a law for every project?
`02` scopes it to "any app whose numbers someone acts on" and the build template says remove it only for an app whose numbers nobody acts on. Codex, a reader, has numbers too (page numbers, percentages, the record-vs-display law) and arrived at rule-shaped conclusions independently. *Trigger:* the next project of either kind — decide whether the section is universal and the scope sentence can go.

### Two Apple platforms in one platform layer
`06` is iOS with a macOS section; `RELEASE_CHECKLIST` is TestFlight with a macOS §F. Fine at two; at three (visionOS, watchOS, a Catalyst variant) the per-platform-appendix pattern noted under "Platform-agnostic claim…" above becomes overdue.

### The two-project merge — first real instance
This copy and the Codex copy both carry the date 2026-09-04. The project name in every revised heading is what distinguishes them. Things the merger will meet: `02` has new sections from both projects, some adjacent (Codex's "Never Ask a Question…" and Icarus's "Design for Nobody Watching" are siblings and cross-reference); `07` and `08` each gained Icarus sections beside Codex ones; `06`'s SwiftData section was corrected by Icarus after Codex left it alone; `08`'s "never say pull" was overruled by Icarus. Newest fact wins; both worked examples stay; where the two projects disagree, the text now says which project said what. *Trigger:* after this merge, decide whether hand-merging still scales (the thread above under "How the kit is revised").

---

*Last updated: 2026-09-04 (Icarus revision)*
