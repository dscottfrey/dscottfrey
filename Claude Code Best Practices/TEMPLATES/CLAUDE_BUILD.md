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

These apply to every line of code in this project. They are not aspirational — they are requirements.

**Occam's Razor:** When there are two ways to solve a problem, choose the simpler one. If Apple's SDK already does something, use it. Avoid "future-proofing" that adds complexity now for benefits that may never materialize.

**Comments are part of the deliverable:**
- Every file begins with a header comment: what this file is, why it exists, how it fits into the module.
- Every function has a plain-English comment before it: what it does, what goes in, what comes out.
- Any non-obvious line or block gets an inline comment.
- When a specific approach was chosen over an alternative, a comment explains why.
- Use `// MARK: - Section Name` to divide long files.

**Document the journey, not just the destination:** If a working solution was reached after several attempts, the comment must capture what was tried and why it didn't work, what the working approach is and *why* it works, and any non-obvious constraint that made earlier attempts fail. Say explicitly: *"This approach was chosen because [X]. Earlier attempts using [Y] failed because [Z]. Do not change this without understanding that constraint."*

**One file, one job:** No file should do more than one thing. ~200 lines is a signal to break it up. Views don't contain business logic. Models don't contain UI code.

**Work with the platform:** If achieving a behaviour requires overriding or working around a standard platform component in a non-trivial way, flag it before writing the code: *"This approach would require working against how [framework] handles [X]. Here's what the standard behaviour looks like, and here's what it would take to override it. Given the simplicity principle, I'd recommend accepting the standard behaviour. Want to proceed anyway?"*

**Every tunable value has a settings home:** Nothing is hardcoded without a conscious decision. Every value a user might reasonably want to adjust gets a setting.

**Every build is identifiable:** Every build produces a unique, automatically-generated build identifier visible in an About screen. Build numbers are set by automated build phases, never maintained by hand. See `Scripts/generate_build_info.sh` and `Scripts/bump_built_info_plist.sh`, plus their two corresponding Run Script build phases (one before Compile Sources, one as the last phase). The About screen displays the marketing version, the build timestamp (`YYMMDDhhmm`), and the short git SHA (with a `+` suffix when the working tree is dirty). Reference: `02_DEVELOPMENT_PHILOSOPHY.md` "Every Build Is Identifiable" and `TEMPLATES/BUILD_NUMBER_AUTOMATION.md` in the Best Practices kit.

**Development signing doesn't expire:** Local development builds use a long-lived, locally-issued code-signing identity (currently a 10-year self-signed certificate), never Xcode's auto-provisioned Personal Team certificate. Configure in Build Settings as `CODE_SIGN_STYLE = Manual`, `CODE_SIGN_IDENTITY = "<CertName>"`, `DEVELOPMENT_TEAM = ""` — applied to every target that loads into the host app's process (app, test bundle, frameworks). Use a separate Debug-only entitlements file with `com.apple.security.cs.disable-library-validation` to keep XCTest working; Release builds retain strict library validation. **Before archiving for distribution, signing must be switched to a Developer ID Application certificate** — this is an explicit release-checklist item, not an automated step. Reference: `02_DEVELOPMENT_PHILOSOPHY.md` "Development Signing Doesn't Expire" and `TEMPLATES/DEVELOPMENT_SIGNING.md` in the Best Practices kit.

**Color is never the sole signal:** Any information conveyed by color must also be conveyed by at least one other channel — text, an icon or shape, position, or some other non-color cue. Color is permitted as reinforcement of meaning, never as the sole carrier. When implementing a UI element where color is the obvious way to convey state, pause and ask: "Is the color carrying information that nothing else is carrying?" If yes, add a second channel before shipping. Exceptions require explicit owner approval recorded in the relevant module directive.

**Swift/SwiftUI projects:** Also read `Docs/06_SWIFT_SWIFTUI_IDIOMS.md` (copied into the project's `Docs/` folder from the Best Practices kit at project setup time). It contains platform-specific rules — modern API discipline, observation patterns, view composition, and common AI-generated-code anti-patterns — that complement the general principles above. Remove this bullet entirely if the project is not Swift/SwiftUI.

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

---

## Owner Accessibility Notes

Accessibility requirements driven by the project owner. These apply to both how Claude Code communicates with the owner during terminal sessions *and* to color choices implemented in the app itself.

The owner has Protanomaly. When providing color-coded information, do not rely on the distinction between Purple/Blue, Green/Brown, or Orange/Green. Use high-contrast labels, distinct icons, or textures instead of color alone.

The same pairs must also be avoided when implementing or proposing colors for the app itself — brand palette, status indicators, chart series, accents, anything visible. The owner reviews every design and uses every build, so a color scheme that visually collapses these pairs for the owner makes both daily use and design review harder. The owner's apps are primarily for the owner's own use; broader accessibility is also a goal but the owner's specific needs take priority when they conflict.

[This is in addition to, not a replacement for, the universal redundancy rule in the development philosophy section above (see "Color Is Never the Sole Signal") — both apply. Edit or remove the owner-specific guidance above based on the actual project owner.]

---

*Build context last updated: [Month Year]*
