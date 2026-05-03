# 03 — Dependency Framework

How to evaluate, justify, and manage external libraries. Every dependency is a liability. This framework ensures you add them deliberately, with your eyes open.

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
Pinned at: 3.8.0 (validated March 2026)
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
