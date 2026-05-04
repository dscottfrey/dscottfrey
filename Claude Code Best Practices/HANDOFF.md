# Handoff — Future Additions and Open Threads

A running log of things to capture, revisit, or decide for the Best Practices kit. Mirrors the Handoff Notes pattern from `05_ARCHITECTURE_DECISIONS.md` — items here are deliberately deferred, not forgotten.

When an item is acted on, mark it ✅ with a brief note about where it landed (which file, which section) and the date. Do not delete resolved items — the history is part of why we trust the kit.

---

## Candidate Topics — Not Yet Covered

### Testing Strategy
The kit is silent on testing. Open questions: what level of test coverage is expected; unit vs integration vs UI; how to spec testability in directives; whether Claude Code should write tests by default or only when asked; how to handle the "tests pass but feature is wrong" failure mode.

*Trigger to capture:* first project that ships to real users, or first time a regression slips through because there were no tests.

### Error Handling and Logging Conventions
No guidance yet on error surface (Result vs throws vs Optional), what gets logged and at what level, how errors are presented to users, or how to structure logs so future debugging sessions can use them.

*Trigger to capture:* first project where logs become important to debugging.

### Security and Secrets Handling
Nothing on API keys, tokens, environment variables, keychain usage, what never goes in git, how to handle credentials in CI. Adjacent: the kit forbids hardcoded values for tunables but doesn't say how to handle hardcoded secrets.

*Trigger to capture:* first project that integrates an external service requiring credentials.

### Performance Profiling Discipline
The kit specifies performance *requirements* go in directives (`04_DIRECTIVE_WRITING.md §5`) but doesn't cover when to profile, what tools, how to record baselines, when "fast enough" wins over further optimization.

### Git and Commit Practices
Root files exist (`git-branching-guide.md`, `committ-files-in-xcode.md`, `collaborating.md`, `Xcode - GitHub setup.md`) but none are pulled into the kit. Decide: fold relevant pieces in as `06_GIT_WORKFLOW.md`, or keep git/setup separate from the directives kit.

*Note:* mining these requires cross-folder edit permission per current rules.

### Session Post-Mortem Pattern
No standing pattern for capturing what was learned in a session — only the directive update itself. A lightweight post-mortem ("what surprised me, what would I tell future-me") could be the source material that feeds back into this kit over time.

*Trigger to capture:* once we have a few cycles of real evolution to draw from.

---

## Meta — Kit-Level Questions

### iOS/Xcode-Specific vs Platform-Agnostic
The kit is positioned as portable but several examples and code skeletons are Swift/iOS-flavored. Decide: explicitly scope the kit to Apple platforms, generalize the examples, or add a small "platform appendix" pattern.

### Cross-Reference Discipline Inside the Kit Itself
The kit teaches cross-referencing as a directive practice but the kit's own files don't cross-reference each other. Worth adding "see `04_DIRECTIVE_WRITING.md §X`" links where concepts overlap (the Handoff Notes pattern is mentioned in both `01` and `05`, for instance).

---

## Active Threads

### Broader Accessibility Coverage
"Color Is Never the Sole Signal" in `02_DEVELOPMENT_PHILOSOPHY.md` is the first accessibility principle in the kit. Other principles worth capturing eventually: VoiceOver / screen reader support requirements; dynamic type and text-size scaling; minimum contrast ratios; reduced-motion preference; minimum touch target sizes; keyboard / Switch Control navigation; haptic feedback redundancy. May warrant promotion to a dedicated `06_ACCESSIBILITY.md` once there are 4+ principles.

*Trigger to expand:* next time a project encounters a real accessibility need beyond color, or the owner wants to spec accessibility for an app.

### Build Template Summary Drift
`TEMPLATES/CLAUDE_BUILD.md` includes a condensed summary of the principles from `02_DEVELOPMENT_PHILOSOPHY.md`. Twice now (Every Build Is Identifiable, Color Is Never the Sole Signal) a new principle was added to `02` and the build template summary was missed on the first pass — discipline since adopted: every time a section is added to `02`, the corresponding bullet in `CLAUDE_BUILD.md`'s "Development Philosophy" section is added in the same edit. Held cleanly when "Development Signing Doesn't Expire" was added on 2026-05-04.

*Trigger to resolve:* if the discipline fails again, consider mechanical alternatives (e.g., have the build template `include` from `02`, or generate it).

### Switch From Self-Signed to Real Developer ID
`TEMPLATES/DEVELOPMENT_SIGNING.md` and the "Development Signing Doesn't Expire" section in `02_DEVELOPMENT_PHILOSOPHY.md` currently describe the self-signed-cert approach. When the project owner has a paid Apple Developer Program membership and a Developer ID Application certificate, both need revisions:

- The principle in `02` stays the same; only the implementation guidance updates.
- The template's "Status of This Reference" section gets replaced/removed, the procedure switches from Keychain-Assistant cert creation to "use your Developer ID Application identity," and the Debug-only library-validation entitlements exception can probably be removed entirely (since Apple-issued certs have a real `TeamIdentifier` that satisfies library validation natively).
- The release-checklist item "switch signing back to Developer ID before archiving" can be reduced to "verify Developer ID is the active identity" or removed if the dev cert and the distribution cert become the same thing.

*Trigger to resolve:* the project owner explicitly tells Claude they have the Developer ID Application certificate and want the kit revised. Until then, self-signing is the right tool.

---

## Resolved

- ✅ **2026-05-04 — Build Number Automation (initial spec).** Added "Every Build Is Identifiable" section to `02_DEVELOPMENT_PHILOSOPHY.md` and reference implementation to `TEMPLATES/BUILD_NUMBER_AUTOMATION.md`. Chose Option B: every build regenerates a `BuildInfo.swift`; Release builds additionally bump `CFBundleVersion` in `Info.plist` for App Store / TestFlight compliance. Initially supported both new-project and retrofit flows.

- ✅ **2026-05-04 — Development Signing (self-signed cert).** Added "Development Signing Doesn't Expire" section to `02_DEVELOPMENT_PHILOSOPHY.md`, plus reference implementation at `TEMPLATES/DEVELOPMENT_SIGNING.md`. Captures the rationale (Personal Team certs expire and are silently revoked on Apple infra rotations), the procedure (Keychain Assistant 10-year self-signed cert, Manual signing identity per target, Debug-only entitlements file with `disable-library-validation` to keep XCTest working, Xcode 16 debug-dylib disabled), and the gotchas discovered during real implementation. Updated `CLAUDE_BUILD.md` philosophy summary in the same edit (drift discipline held). New active thread tracks the eventual switch to a real Developer ID Application certificate.

- ✅ **2026-05-04 — Build Number Automation (refined from real implementation).** Original spec was put through a real project setup, which surfaced multiple bugs. Folded the findings back into the kit: switched timestamp format to `YYMMDDhhmm` (10 chars); split the work into two scripts and two Run Script phases (`generate_build_info.sh` before Compile Sources, `bump_built_info_plist.sh` as the last phase); changed Release-mode `CFBundleVersion` mutation to target the *built* `Info.plist` (works for both hand-maintained and `GENERATE_INFOPLIST_FILE = YES` modes, never mutates a committed file); switched `BuildInfo.swift` from gitignored-and-untracked to tracked-as-placeholder (synchronized groups in Xcode 16+ require the file present at build-graph construction time); added the User Script Sandboxing build-setting step; added a "Known Gotchas" section in the template covering quote stripping, About panel name casing with `GENERATE_INFOPLIST_FILE`, `git status` noise tolerance, synchronized-group target membership, and `.gitignore`/`git add` interaction. Updated `02_DEVELOPMENT_PHILOSOPHY.md` and the build template's philosophy summary to match. Reframed the kit so build identification is set up from day one on new projects only — retrofit flow is no longer supported, and `prompt_retrofit_build_number_automation.txt` was removed.

---

*Last updated: 2026-05-04*
