# 04 — Directive Writing

How to write directives that Claude Code can actually build from. A bad directive produces a lot of code that needs to be thrown away. A good directive produces code you keep.

---

## What a Directive Is

A directive is a specification document that Claude Code reads before writing any code. It is not a requirements document in the traditional sense — it is closer to a design brief combined with an architecture decision record. It must answer:

- What does this module do, and why does it exist?
- What are the exact behaviours required?
- What is explicitly NOT required (anti-requirements)?
- What technical approach is specified?
- What data does it own and what does it expose to other modules?
- What are the open questions that still need resolving?

---

## Standard Structure

Every module directive follows this structure. Sections can be expanded or contracted but should all be present.

```
# [Project] — Module N: [Name] Directive

Module, Priority, Dependencies header block

## 1. Purpose
One or two paragraphs. What does this module do and why does it exist?
Why is it built this way rather than another way?

## 2. Core Requirements
The specific behaviours this module must exhibit. Use subsections (§2.1, §2.2...).
Include: the requirement, the rationale, the implementation approach, and any anti-requirements.

## 3. Architecture / Implementation
The technical design. Data flows, component relationships, key APIs used.
Include code skeletons for complex patterns.
Reference iOS/API versions for anything non-obvious.

## 4. [Module-Specific UI / Data / Integration sections]
Whatever makes sense for the module.

## 5. Performance Requirements
Specific, measurable targets. Not "fast" — "< 300ms on iPhone 12 or newer."

## 6. [Accessibility / Platform requirements if applicable]

## 7. Data Model
The structs, enums, and models this module owns.
Include Swift code blocks for anything non-trivial.

## 8. Open Questions
Things not yet decided. Close them out with ✅ when resolved — don't delete them.

---
Status footer + last updated date
```

See `TEMPLATES/MODULE_DIRECTIVE.md` for a blank version.

---

## The Most Important Thing: Rationale

The most common mistake in directive writing is stating decisions without explaining them.

**Wrong:**
> Pagination uses CSS Columns.

**Right:**
> Pagination uses CSS multi-column layout rather than JavaScript scroll-position estimation. JavaScript measurement is fragile — content height can change after fonts swap or images load, producing wrong page counts. CSS Columns hands pagination to the browser's layout engine, which provides a stable integer column count. Page boundaries are deterministic.

The rationale matters because:
- Claude Code can only apply a rule correctly if it understands why the rule exists
- When an edge case arises that the directive didn't anticipate, the rationale gives Claude Code enough context to make a good judgment call
- A future planning session (or a different AI session) will understand the history and not relitigate closed decisions
- You will understand your own decisions six months from now

**Every decision in a directive should be accompanied by its rationale.**

---

## Anti-Requirements

State explicitly what the module does NOT do. These are as important as the requirements.

Anti-requirements prevent:
- Claude Code adding "helpful" features you didn't ask for
- Scope creep during implementation
- Future sessions re-opening closed questions
- The module acquiring responsibilities that belong to a different module

**Good anti-requirement:**
> *"The parser does not paginate. That happens after the WebView renders the chapter. The parser does not manage reading position — that is SwiftData and the Sync Engine."*

**How to write them:** Add a "What This Does NOT Do" subsection to any section where the boundary might be ambiguous. Be specific about what is excluded and which module or component is responsible instead.

---

## Status Markers

Use consistent markers to communicate decision status:

| Marker | Meaning |
|---|---|
| ✅ **Decided.** | Decision is closed. Implementation should follow this. |
| ⚠️ | A caveat or known limitation. Not an error — an acknowledged tradeoff. |
| 🔄 In progress | Work has started but is not complete. |
| *(no marker)* | Open question or unresolved choice. |

When a decision is made, update the marker to ✅ and add the decision inline. **Do not delete open questions after they are resolved** — the history of how you arrived at decisions is valuable, especially for AI-assisted projects where future sessions may not have context.

---

## Open Questions Section

Every directive has an open questions section. Use it actively.

- Add questions as they arise during planning
- Close them out with ✅ and the resolution when decided — keep the text, add the answer
- Reference the section where the decision lives: ✅ **Decided.** See §3.2 for full spec.
- Questions that are explicitly out of scope for v1 are noted as such

The open questions section is the memory of the planning process. Do not clean it up.

---

## Code Skeletons

For complex implementation patterns, include a code skeleton in the directive. This is not final code — it is the *shape* of the solution: the key types, function signatures, and data flows.

Code skeletons serve two purposes:
1. They force precision. Writing the skeleton reveals ambiguities in the prose description.
2. They give Claude Code a concrete starting point, reducing the chance it will invent a different structure.

```swift
// Example skeleton: just the shape, not the implementation
struct PageCache {
    private var images: [PageKey: UIImage] = [:]
    
    func image(for page: Int, chapter: String) -> UIImage?
    mutating func store(_ image: UIImage, for page: Int, chapter: String)
    mutating func invalidate(chapter: String)
}
```

Include skeletons when: the data structure is non-obvious, the component has a specific interface contract, or the implementation involves a pattern that Claude Code might implement differently by default.

---

## Cross-References

When a directive refers to a decision or data structure that lives in another directive, reference it explicitly by file and section:

> *"The character offset format is specified in `06_ANNOTATION_SYSTEM.md §3.1` — use Int, not Double."*

This prevents the common failure mode of two modules independently specifying the same data structure in incompatible ways. During planning, cross-check all directives before declaring the spec complete.

---

## API and Platform Version Notes

When a key API has a minimum iOS version requirement, note it inline:

> *"`WKWebView.find(_:configuration:completionHandler:)` — iOS 16+"*

This is especially important for anything new or recently added to the platform. Do not assume Claude Code knows which APIs are available on which iOS versions — note the version explicitly.

---

## The Status Footer

Every directive ends with a status footer:

```
*Module status: [brief description of current state — what's spec'd, what's built, what's pending]*
*Last updated: [Month Year]*
```

The status footer gives any new planning session an instant read on where this module stands without reading the whole document.

---

## Updating Directives

**Directives are living documents.** They are updated every time a decision is made.

The rule: **the moment a decision is made in conversation, the directive is updated before the conversation continues.** Decisions that live only in conversation history are effectively unmade — they are invisible to Claude Code and to future sessions.

When updating:
- Update the specific section where the decision lives
- Close out the open question if there was one (✅ marker)
- Add rationale to the decision
- If the decision affects another module's directive, update that too and cross-reference

---

## The Directive Is the Source of Truth

If the directive says X and Claude Code builds Y, one of two things happened:
1. The directive was ambiguous (update the directive to be more explicit, then correct the code)
2. Claude Code made an error (correct the code with a reference to the directive section)

Either way, the directive wins. The answer is never to update the directive to match the code without a deliberate decision that the code is actually right.
