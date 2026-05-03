# [Project Name] — Module N Addendum: [Feature Name]

**Parent directive:** `[NN_MODULE_NAME.md]`  
**Addendum type:** Planned feature / Experimental branch  
**Status:** Planned — not yet built  
**Branch survivability:** If the branch this addendum belongs to is killed, this file survives. The parent directive remains clean and can be recertified independently. Fold this addendum back into the parent directive if and when the feature ships.

---

## What This File Is

This addendum holds the specification for [feature name] — a planned addition to Module N ([Module Name]) that is being developed on a separate branch.

It is kept separate from the parent directive so the parent can be treated as a stable, certified spec regardless of whether this feature ships. Features planned on experimental branches go in addenda, not the main directive.

---

## §A1. [Feature Name]

### Purpose

[One paragraph. What does this feature do and why? What problem does it solve? Why add it rather than leaving it out?]

### What This Does NOT Do

[Anti-requirements. What is explicitly out of scope for this feature?]

- Does not [X]
- Does not [X] — [brief rationale for the explicit exclusion]

### Behaviour

[The specific behaviours this feature must exhibit. Be as precise as the parent directive. Include:]
- **Trigger:** how the feature is activated
- **The interaction:** what happens, step by step, from the user's perspective
- **Edge cases:** what happens in non-ideal conditions
- **Explicit rejections:** design choices that were considered and ruled out, with rationale

### Implementation Approach

[Technical design. How is this built? What APIs are used? If the approach is non-obvious, include a code skeleton or data flow description.]

```swift
// [Description of what this is and why it is structured this way]
struct [TypeName] {
    // [structure]
}
```

### Integration with Parent Module

[How does this feature connect to the parent module? Does it add to a data model? Does it extend an existing component? Are there cross-references to other modules?]

Cross-references:
- [Reference to another directive section if applicable, e.g. `See 06_ANNOTATION_SYSTEM.md §3.1 for the character offset format used here`]

---

## Open Questions

[Questions specific to this addendum. Same format as parent directive.]

- **[Question]** — [context]

- ✅ **[Closed question]** — **Decided.** [Resolution.]

---

## Fold-Back Notes

[When this feature ships and this addendum is ready to be folded into the parent directive, record here what sections it adds to, what it modifies, and any cross-module updates required.]

When folding back:
- Add §[N.N] [Feature Name] to `[NN_MODULE_NAME.md]`
- Update §[N.N] [Affected section] in `[NN_MODULE_NAME.md]`
- Remove this addendum file
- Update any cross-references in other directives

---

*Addendum status: [Planning / Spec complete / In progress / Complete — ready to fold back]*  
*Last updated: [Month Year]*
