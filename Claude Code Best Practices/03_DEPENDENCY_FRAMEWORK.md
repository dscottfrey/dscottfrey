# 03 — Dependency Framework

How to evaluate, justify, and manage external libraries. Every dependency is a liability. This framework ensures you add them deliberately, with your eyes open.

**Revised 2026-09-04** with a worked example from Codex, the project this framework was written for — which kept zero dependencies right up to the one layer where the framework said a library was justified, and then learned what the framework had left out.

**Revised 2026-09-04, Icarus** with a second worked example: a vendored, not packaged, vendor SDK for lab sensors — where the directive record was written on day one and still has a blank in it, where the directive itself served as the project skill, and where the *hardware* turned out to need the same record as the library.

---

## Zero Dependencies Is the Goal State

The target for any project is zero external dependencies. This is not always achievable, but it is the right north star. Every library you add is:

- A maintenance burden (you must update it when it breaks with OS updates)
- A potential source of breaking changes outside your control
- A security surface
- A thing that can be abandoned, removed, or license-changed by its maintainer
- A constraint on your architecture (you work around the library's opinions)

**The question is not "Should we add this dependency?" The question is "Can we achieve the same result without it, and at what cost?"**

Zero dependencies is the goal state. It is also recorded as such in the overall directive, so Claude Code knows not to casually reach for libraries.

---

## Before Adding Any Dependency — Answer These Questions

Before adding any external library, answer all of these:

1. **Does Apple's SDK already do this?** Check the documentation. Apple's SDK is enormous and grows every year. If it's there, use it.

2. **Can we write a focused custom implementation?** Estimate the scope honestly. A 300-line custom parser is often better than a 50,000-line library that does 100 things you don't need.

3. **What exactly do we need from this library?** Not what it can do — what we will use. If the answer is "20% of its features," that's a signal to consider a custom implementation.

4. **What is the maintenance posture?** Is it actively maintained? Does it have a clear release history? What happens if it stops being maintained?

5. **What are the transitive dependencies?** A library that pulls in five other libraries is five dependencies, not one.

6. **What is the license?** MIT, BSD, and Apache 2.0 are permissive and appropriate. GPL and AGPL have viral implications for commercial apps.

7. **What is the fallback plan?** If this library disappears or breaks, what do we do? The answer should not be "we are stuck."

---

## The Targeted Dependency Principle

When you decide a dependency is justified, take only what you need.

Many libraries are collections of modules. A library might have a parser module, a rendering module, a navigation module, and a networking module. If you only need the parser, import only the parser module. Do not import the full library "just in case."

**Document what you are importing and, equally explicitly, what you are not importing and why.**

Example:
```
Importing:  ReadiumStreamer   — epub parsing and HTTP content serving
NOT importing: ReadiumNavigator — Codex implements its own rendering pipeline
NOT importing: ReadiumOPDS     — out of scope
```

This makes it clear to every future developer (and AI session) exactly what role the library plays and what is not its responsibility.

---

## Recording a Dependency Decision

Every dependency added to the project is recorded in the overall directive under a dedicated section. The record includes:

- **What it is** — the library, its purpose, the version pinned
- **Why it was added** — what problem it solves that we couldn't solve without it
- **What we use from it** — the specific modules or functions we import
- **What we do NOT use** — equally important; prevents scope creep
- **Trigger to revisit** — the specific condition under which we would re-evaluate this decision (e.g., "if the deprecated HTTP server API is removed, migrate to WKURLSchemeHandler")
- **Fallback plan** — what happens if the library becomes unavailable or unmaintained

Do not add a dependency without writing this record. The record is not a formality — it is how future sessions start with context instead of assumptions.

---

## Pinning Versions

Always pin dependencies to a specific version, not a range or "latest." Document the pinned version and when it was validated.

```
Package: ReadiumSwiftToolkit
Pinned at: exactVersion 3.11.0 (validated 2026-08-31)
Reason for pin: API validated against this version; 
                later versions may change the HTTP server API
```

**Never silently update a pinned dependency.** Treat a version update as a deliberate decision that requires re-validation.

---

## The Trigger-to-Revisit Pattern

Every dependency decision includes an explicit trigger: the specific condition under which the decision should be re-evaluated.

Examples:
- *"Revisit if the custom parser accumulates more than three epub-compatibility workarounds — at that point ReadiumStreamer's edge-case handling may be worth the dependency."*
- *"Revisit if the deprecated GCDHTTPServer API is removed from the library — at that point migrate to a custom WKURLSchemeHandler."*
- *"Revisit if [Library X] introduces a breaking change that requires significant adaptation — at that point evaluate writing a custom implementation."*

The trigger condition prevents two failure modes: (1) never revisiting a decision that should be reconsidered, and (2) constantly second-guessing a decision that is working fine.

---

## Prefer Libraries That

- Have no transitive dependencies of their own (or minimal ones)
- Are actively maintained with a clear release history
- Have permissive open-source licenses (MIT, BSD, Apache 2.0)
- Have a clear Swift Package Manager (or equivalent) integration
- Present a narrow, stable public interface — the smaller the API surface you depend on, the easier it is to adapt if the library changes
- Are widely used in production apps — battle-tested implementations have solved the edge cases you haven't encountered yet

---

## The Custom Implementation Threshold

Consider a custom implementation when:

- The library does 5× more than you need
- The library's opinionated design conflicts with your architecture
- The library would require you to restructure your code to fit its patterns
- A focused custom implementation would be under 500 lines
- The feature set you need is stable and well-understood (not a moving target)

Consider a library when:
- The problem domain is genuinely hard and the library has years of battle-testing
- The library solves a whole category of edge cases you would otherwise encounter one by one
- The library's architecture is compatible with yours (you can use it without restructuring around it)
- The maintenance cost of a custom implementation would exceed the dependency risk

---

## Worked Example — Codex and the Readium Swift Toolkit *(learned on Codex)*

Codex held the zero-dependency goal for everything but the epub layer. Parsing epub, serving its resources to a web view, and paginating reflowable HTML is exactly the case the "Consider a library when" list describes: a genuinely hard domain, years of battle-testing, a whole category of edge cases (malformed packages, missing anchors, nested tables of contents) that would otherwise arrive one by one. The **Readium Swift Toolkit** was adopted, pinned at 3.8.0 (later `exactVersion 3.11.0`, upgraded 2026-08-31 as a card of its own), with the targeted-dependency principle applied — the parser and navigator products imported, the OPDS and LCP products not.

Four things the framework did not say, and now does:

### 1. The record must live where the directive says it lives — and it drifted

This framework says every dependency is recorded in the overall directive under a dedicated section. Codex's `00_OVERALL_DIRECTIVE.md` §6.6 **still reads "Current external dependency status: none"** four months after Readium was pinned. The decision was recorded — thoroughly — in `Docs/READIUM_NOTES.md`, in the handoff, and in the code. It was never written back into the one place the directive itself names. Every new session that reads the directive first is told the project has no dependencies.

The rule was right; it was not followed, and nothing checked. **Add the dependency record to the release checklist and the conformance audit**, so a session is forced to read §6.6 against `Package.resolved` at least once per build.

### 2. The trigger-to-revisit fired, and the notes caught it

The pin's recorded trigger was the library's HTTP-server API — the reason Codex ran a local server at all. Research on 2026-08-05 found the server was already obsolete upstream; verification against the compiled checkout on 2026-08-28 found it had been obsolete *at 3.8.0 itself*, the pinned version. The migration plan that had been written (a custom URL-scheme handler, "50–80 lines") was **cancelled, not executed** — the right move was to delete the server, its adapter product and a transitive dependency, which became a card.

Two lessons. A trigger written down is a trigger that gets noticed. And **a changelog is not what compiles**: the first correction was made from release notes and a research pass challenged it, correctly; the answer came from `git status` in the package checkout. Verify a claim about a pinned version against the source at that tag.

### 3. The operational rules for a dependency belong in a project skill, not only in comments

A library used seriously accumulates rules that were each paid for on a specific day: which initializer to call, which reported value goes stale under load and must never drive a correction, which delegate fires twice, which preference is ignored on the main thread. Codex wrote these into code comments per the philosophy — and the same evening was still spent twice, because a comment is found only by someone already reading that file.

The fix was a **project skill**: `Docs/skills/readium-in-codex/SKILL.md`, a single file of the hard-won rules with a trigger list in its frontmatter (every type and method name the library exposes that has bitten), loaded automatically before any session touches that surface. Its shape:

- a header stating it is the master copy and how it is installed (on Codex, a symlink from `.claude/skills/` — so it cannot diverge);
- *"Every rule here was paid for"* — each rule names the day it broke and what the user saw;
- `file:line` receipts pointing at the comment in the code that holds the long version;
- an opening section on *why this project is not blocked where everyone else using the library was*, so a new session does not re-litigate the architecture.

**When a dependency has cost you more than one evening, write its skill.** The comments stay; the skill is the index that makes them findable before the mistake rather than after.

### 4. An installed expert skill outranks a research pass

Two sources will disagree about a framework: a skill written by a named practitioner who ships it in production, and a web-research pass by a bot that labels its own confidence (`[fetched]`, `[snippet]`, `[unverified]`) precisely because much of it is index text it never read. The owner's ruling (2026-08-28): *"I would believe Paul Hudson's skill over the research."* Follow the skill and say which source was dropped; do not average them, and do not present the research as an equal counterweight.

**The one carve-out is a reason to speak, not to override.** When the research is *transcribing a primary source* — Apple's engineers, Apple's developer support, the vendor's own documentation — the conflict is not skill-versus-bot, it is skill-versus-vendor, and it is worth one sentence to the owner before proceeding either way. Still the owner's call.

### The pin is a decision; upgrading is a card

A pinned version was validated on a date against a body of behaviour. Upgrading re-opens every rule in the skill. On Codex the upgrade is a numbered card with its own preconditions (delete the dead server first; the upgrade is cleaner without it), sequenced against other work, and never done as a side effect of "let me just bump it." Treat `Package.resolved` as source, and a change to it as a change that needs its own build-and-report round.

---

## Worked Example — Icarus and the Yoctopuce SDK *(Revised 2026-09-04, Icarus)*

Icarus has exactly one non-Apple dependency: the Objective-C SDK for the light and temperature sensors it reads, **copied into the tree** (the vendor does not ship it as a package). It is a different case from Readium in three ways, and each says something the framework did not.

### 1. The record was written on day one — and the pin was never filled

The dependency record in Icarus's overall directive is a model of this framework: what is used (listed to the method), what is not, the fallback plan (bypass the SDK and call the hub's HTTP API directly), and four triggers to revisit. It was written before the first build. Four months later, the pin line still reads *"`<to be filled at first build: the YAPI version string and date validated>`"*. The kit was right that the record must live in the directive; Codex's failure was a record that never reached the directive, Icarus's is a record that reached it with a blank in the load-bearing field. **A vendored dependency has no `Package.resolved` to check the directive against, so the pin is a version string plus a date, and someone has to type it.** Put "pin filled?" on the release checklist beside "record present?".

### 2. When the dependency is small, the directive can be the skill

Codex needed a project skill because the library was large and its rules were scattered across comments. Icarus put the hard-won rules — must disable exceptions before any other call, every background call in an `autoreleasepool`, one serial queue, which write calls return `Int32` not the status constant, a factory that never fails so the handle must be tested online first — into a **"Lessons Inherited From the Prior Art"** section at the top of the integration directive, each with a verbatim code block and the words *"do not remove this line"*. A predecessor project had paid for every one. Because the directive is read before any code touches the module, that section did the skill's job. The test is not "skill or directive" but *is it read before the mistake?* — a section a session must pass through on the way to the code qualifies.

### 3. Hardware is a dependency, and its behaviour needs the same record

The sensor *hardware* cost Icarus more evenings than the SDK did, and none of it was in any document until it had been paid for:

- The vendor's note that a configuration call "is a no-op" was for their *digital* sensors; on the analog board it was mandatory, and removing it on that belief left every channel reporting raw ohms (2026-07-08).
- A firmware calibration call built only a two-point table; a reading just outside it came back as **−273 °C**. Found by reading the SDK's own source, not its documentation.
- On a *different* board the same configuration call really is a no-op, so a "skip if already configured" guard that tested it skipped every channel and wrote nothing.
- The hub's web service redirects its documented port to a TLS port with a self-signed certificate, and a "new version available" prompt must be declined because a reachability fix is tuned to the installed one.

Each is now in the integration directive with the date. **The record for a device is the same six fields as for a library** — what it is, what is used, what is not, the trigger to revisit, the fallback — plus one more: *what it does that its documentation does not say*. And the Codex rule holds with more force: **a vendor's changelog or note is not what runs; the source, or the device on the bench, is.**

### 4. Verify a dependency claim against the source at the pinned version

Same lesson as Codex, second project: the −273 °C bug was settled by opening `yocto_temperature.m` and finding the two-point table, after a session of theories. When a behaviour is in question, read the vendored source at the version actually compiled before proposing a fix.
