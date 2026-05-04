# 02 — Development Philosophy

Principles that apply to every line of code in every project. These are not aspirational — they are requirements. Put them in your build `CLAUDE.md` and in your overall directive. They apply to every session, every module, every commit.

---

## Occam's Razor — Simplest Solution That Works

When there are two ways to solve a problem, choose the simpler one. Always.

- If Apple's SDK already does something, use it rather than building a custom version
- If a problem can be solved with 20 lines of straightforward code or 100 lines of clever code, write 20 lines
- Avoid "future-proofing" that adds complexity now for benefits that may never materialize. Build for what the app does today. Refactor when requirements actually change.
- When evaluating a library or approach: "Is this the simplest thing that will work reliably?" — not "Is this the most powerful option?"

**Clever code is a liability. Simple code is an asset.**

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

---

## Every Tunable Value Has a Settings Home

Nothing in the app is hardcoded without a conscious decision that it should be. Every value a user might reasonably want to adjust gets a setting, even if it requires several taps to reach.

**Two-tier settings pattern:**
- **Surface settings:** visible immediately. The things most users will touch.
- **Advanced settings:** behind an "Advanced" row or section. Power-user controls that most users never need, but that should exist when needed.

The rule: if a value was discussed during planning as a tuneable number or behaviour, it becomes a setting. When in doubt, make it a setting and put it in Advanced with a clear inline explanation.

This is not an invitation to build a settings screen that requires a manual. Advanced settings should still be well-labelled. But they should exist.

---

## Every Build Is Identifiable

Every build of the app produces a unique, automatically-generated build identifier that is visible to the user in an About screen. No two builds are ever indistinguishable.

This is a discipline for the project owner first, not for end users. When troubleshooting — especially via screenshots, recordings, or a verbal description from someone else — the single most useful piece of information is "which build is this?" Without it, you spend the first ten minutes of every debugging session trying to figure out whether the user is running the build with the fix or the one before it.

**The rule:** the build identifier is set by an automated script at build time, not maintained by hand. A human cannot be relied on to remember to increment a number. They will forget, exactly when it matters most.

### The Approach

`CFBundleVersion` (the build number on Apple platforms) is set by a Run Script build phase to a Unix timestamp — either seconds since epoch or a compact `YYYYMMDDHHMM` form. The About screen displays three things:

- The marketing version (`CFBundleShortVersionString`, e.g. `1.2.0`) — set by hand at release time
- The build number (the timestamp) — set automatically on every build
- The short git SHA of `HEAD` at build time — set automatically on every build, with a trailing `+` if the working tree was dirty

Example About display: `1.2.0 (2604051847 · a3f9c1e+)`

The `+` on the SHA matters. A dirty working tree means the build does not correspond to any committed state — without the marker, the SHA alone is misleading.

### Why Timestamp Rather Than Commit Count

A common alternative is to set the build number to `git rev-list --count HEAD` so it tracks commits. This fails in the exact case the build identifier most needs to succeed: troubleshooting. During a debugging session you typically rebuild many times *without* committing — three rapid debug builds would all report the same build number. A timestamp is always unique and always monotonically increasing.

### App Store and TestFlight Compatibility

Apple's App Store and TestFlight require `CFBundleVersion` to be monotonically increasing per marketing version. A Unix timestamp satisfies this trivially — every new build has a larger value than the previous one. No special handling is needed when the project eventually ships through these channels. Plan for this from the first build, even on projects that are nowhere near submission yet; retrofitting it under deadline pressure is exactly the kind of thing that gets skipped.

### Implementation

The build-time automation is identical on iOS and macOS — both rely on a Run Script build phase that updates `Info.plist` (or the equivalent build settings). What differs is the *display* layer: macOS apps can lean on `NSApplication.orderFrontStandardAboutPanel(_:)` with a custom credits dictionary; iOS apps need a custom About view.

A reference script and About-screen snippet live in `TEMPLATES/BUILD_NUMBER_AUTOMATION.md` so they are copied into new projects rather than re-derived. The directive in any new project's build `CLAUDE.md` must require this practice and point Claude Code at the reference template — Claude Code should not invent its own version.

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

This is the first accessibility principle captured in this kit. It is not the only one that matters; it is the one most often violated.

---

## The Development Model Note

When a project is AI-assisted and directed by a non-developer owner, two additional rules apply:

1. **Plain English explanations.** When Claude Code surfaces a question or explains a decision, it is in plain English. Technical jargon is explained in context, not assumed.

2. **Summarize before starting.** Before writing code for a new module or feature, Claude Code summarizes what it is going to build and in what order, giving the owner a chance to redirect before work begins.
