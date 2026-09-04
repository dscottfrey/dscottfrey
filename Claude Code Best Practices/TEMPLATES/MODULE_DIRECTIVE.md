# [Project Name] — Module N: [Module Name] Directive

**Module:** [Module Name]  
**Priority:** [Core / High / Medium / Low]  
**Depends on:** [List other modules this one depends on, or "None"]  
**Depended on by:** [List modules that depend on this one, or "None"]

---

## 1. Purpose

[One to two paragraphs. What does this module do and why does it exist? What problem does it solve? Why is it built this way rather than another way? This is not a list of features — it is a statement of purpose.]

### What This Module Does NOT Do

[Explicit anti-requirements. State what is out of scope for this module, and which module or component is responsible instead. Be specific.]

- Does not [X] — that is handled by [Module Y].
- Does not [X] — that is out of scope for v1.
- Does not [X] — [brief rationale].

---

## 2. Core Requirements

### §2.1 [Requirement Name]

[The specific behaviour this module must exhibit. Include:]
- **The requirement:** what must happen
- **The rationale:** why this is the right approach (not just what)
- **The implementation approach:** how it is built
- **Anti-requirements:** what it does NOT do that might be assumed

### §2.1.1 Rulings — dated and attributed

[When the owner decides something about this requirement, append it here in the
owner's words, with the date: **RULED (Owner, 2026-08-27):** "…". A reversal is
appended as a reversal ("reverses the 08-20 rule"), never edited into the original.
The date is the address other documents cite.]

### THE [NAME] LAW

[Only when a rule has been paid for more than once. One line for the rule, in
capitals if it recurs as bugs; the cases it was learned from; and the test a reader
can apply ("name the guard's consumer"). Cite the law by name in code comments that
enforce it. See `04_DIRECTIVE_WRITING.md` — "Laws".]

**Incident of record — [run or date].** [The numbers, the quote, what it cost,
each consequence mapped to the rule it broke. Kept beside the law so it cannot be
argued away later. *(Revised 2026-09-04, Icarus.)*]

### §2.1.2 Superseded — [what fell, and when]

[When a rule in this module is set aside: ~~strike the original text~~, add
"Superseded (Owner, YYYY-MM-DD)" and what replaced it. Never delete. The same
convention covers a lifted anti-goal and a carve-out, whose *boundary* is stated
in the same sentence. *(Revised 2026-09-04, Icarus.)*]

### §2.2 [Requirement Name]

[Repeat for each core requirement. Use subsections liberally — it is easier to cross-reference §2.3 than "the third paragraph of the requirements section."]

### §2.3 [Requirement Name]

[...]

---

## 3. Architecture / Implementation

[The technical design. Data flows, component relationships, key APIs used. This section is for the *how*, where Section 2 is the *what*. Reference iOS/API versions for anything non-obvious.]

### §3.0 Lessons Inherited — do not re-derive *(Revised 2026-09-04, Icarus)*

[Only for a module that wraps a dependency, a device, or a platform component with
non-obvious crash-avoidance rules — a predecessor project's, or this one's. Each
lesson: the rule, the verbatim code block, **why** in enough detail that a reader
can tell whether it still applies, and the words "do not remove this line". Icarus
carries seven such lessons at the top of its sensor-SDK directive and four at the
top of its display-window directive; because the directive is read before any code
that touches the module, this section does the job of a project skill for a small
dependency. See `03_DEPENDENCY_FRAMEWORK.md`, the Icarus worked example.]

### §3.1 [Component or Flow Name]

[Describe the component or flow. Include a code skeleton if the structure is non-obvious or if Claude Code might implement it differently by default.]

```swift
// Example skeleton — just the shape, not the implementation
struct [TypeName] {
    // properties

    func [methodName]([param]: [Type]) -> [ReturnType]
    func [methodName]([param]: [Type]) async throws -> [ReturnType]
}
```

### §3.2 [Component or Flow Name]

[...]

---

## 4. [Module-Specific Section — UI / Data / Integration]

[Add sections as appropriate for the module. Examples:]
- **4. UI Behaviour** — for modules with significant view layer
- **4. Data Flows** — for modules that transform or move data
- **4. External Integration** — for modules using external services or APIs

---

## 5. Performance Requirements

[Specific, measurable targets. Not "fast" — not "as fast as possible." Concrete numbers tied to specific hardware baselines.]

- [Operation X] completes in < [N]ms on [minimum supported device]
- [Operation Y] uses < [N]MB memory during [condition]
- [Operation Z] does not block the main thread for more than [N]ms

---

## 6. Accessibility / Platform Requirements

[If applicable. Otherwise remove this section.]

- [Requirement]
- [Requirement]

---

## 7. Data Model

[The structs, enums, and models this module owns. Include Swift code blocks for anything non-trivial. Note which types are shared with other modules and cross-reference where the canonical definition lives.]

```swift
// [Description of what this type represents and why it is structured this way]
struct [TypeName] {
    let [property]: [Type]   // [inline comment explaining this field]
    let [property]: [Type]   // [inline comment explaining this field]
    var [property]: [Type]   // [inline comment explaining this field]
}
```

```swift
enum [TypeName] {
    case [case]   // [inline comment]
    case [case]   // [inline comment]
}
```

---

## 8. Open Questions

[Things not yet decided. Add questions as they arise during planning. Close them with ✅ and the resolution when decided — do not delete them. The history of how you arrived at decisions is valuable.]

- **[Question]** — [context, options being considered]

- ✅ **[Closed question]** — **Decided.** [The resolution and brief rationale. See §[N.N] for full spec if the decision warrants it.]

- **[Question marked out of scope]** — Out of scope for v1. Revisit if [trigger condition].

---

*Module status: [Planning / Spec complete / In progress / Module complete — brief description of current state]*  
*Last updated: [Month Year]*
