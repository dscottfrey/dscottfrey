# 04 — Directive Writing

How to write directives that Claude Code can actually build from. A bad directive produces a lot of code that needs to be thrown away. A good directive produces code you keep.

**Revised 2026-09-04, Icarus.** Four months of a second project added what happens when the directive is the thing that is wrong: drift runs in both directions, and the audit for it must be a report rather than a fix. Sections marked with that date are new or refined from Icarus.

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

**The same applies to rules and anti-goals that fall *(Revised 2026-09-04, Icarus)*.** A rule the owner sets aside is struck through — ~~like this~~ — with *"Superseded (date)"* and the reason, in every document that stated it. Icarus did this for its accessibility section, six anti-goals and a "never pause" rule's one exception, so a session that remembers the old rule meets its supersession instead of re-arguing it. Silent deletion is how a dead rule gets rediscovered and re-imposed.

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

## Rulings Are Dated and Attributed

**Added 2026-09-04, from Codex.** A decision in a directive carries who made it and when: *"(Scott, 2026-08-27)"*, *"RULED 2026-08-20"*, *"reversed 2026-09-03"*. Not as ceremony — as an address.

Why it earns its place:

- A later session can tell a **ruling** from a **proposal**. Unattributed prose reads as settled when half of it was the assistant's draft.
- **Reversals are recorded as reversals.** When the owner reversed a page-numbering rule ("the left leaf is always ODD — reverses the 08-20 even doctrine"), the directive says so in those words. Editing the old text silently would have left every citation of the old rule pointing at nothing.
- The date is what lets a card, a memory file and a code comment all cite the same decision (`§7.1, Scott 2026-08-27`) and be checked against each other.

### Laws — when a rule recurs, name it

Some rules on Codex were rediscovered three or four times, each time as a new bug: the same confusion between what may be *recorded* and what may be *displayed* produced three blank-page-number bugs in one evening. The fix was to **name the rule and write it in capitals** — the Record-vs-Display Law, the Parking Law, the Blur's Law, the Dark Adaptation Law — and cite the name.

A law is a rule that has been paid for more than once. Give it:

- **A name** short enough to say in a sentence.
- **The rule in one line**, then the cases it was learned from.
- **A test** the reader can apply: for the Record-vs-Display Law, *"name the guard's consumer — a guard that cannot name what reads its output is in the wrong place."*
- **A home** in the directive (a `### THE X LAW` subsection), a pointer in memory, and the name in any code comment that enforces it.

Do not promote a rule to a law on its first occurrence. The second time the same bug arrives wearing different clothes is the signal.

**Attach the incident of record *(Revised 2026-09-04, Icarus)*.** Beside the rule, in the directive, write the run or the day it was paid for — the numbers, the quote, what it cost — mapping each consequence to the rule it broke. Icarus's quantitative-integrity section carries its five-day run as an *"Incident of record"* for exactly one reason, stated in the handoff: *"so the rule keeps its scar and doesn't get argued away later."* A rule without its incident is a preference; a rule with one is evidence.

**Placement states precedence *(Revised 2026-09-04, Icarus)*.** Where a rule sits in a document is a claim about its rank. Icarus put its integrity rule in *Core Project-Wide Requirements* beside the endurance requirement, not in the philosophy list — and in the project `CLAUDE.md` it is mirrored **above** Occam's Razor, because the two pull against each other and the order says which wins. When two principles can conflict, order them on purpose and say why.

---

## Directives Grow by Addenda and Dated Sections, Not Rewrites

A directive on a live project is not rewritten. It grows:

- **Dated sections** for rulings (`### 7.1 THREE WAYS, ALL OF THEM RIGHT — (Scott, 2026-08-27)`), appended where they belong.
- **Addenda** (`NN.1_MODULE_ADDENDUM.md`) for whole features planned on a branch.
- **Corrections in place, marked as corrections.** *"Corrected 2026-08-28, then VERIFIED AGAINST THE COMPILED SOURCE"* stays in the text so the next reader knows the claim was once wrong and how it was checked. **And say what it used to say** *(Revised 2026-09-04, Icarus)*: *"Corrected 2026-07-29: this section previously said 'triggers pause + dialog', which was superseded by the never-pause fault model and was never updated."* A correction that names the old wording lets a session that remembers the old wording recognise it as old.

Rewriting loses the trail. On an AI-assisted project the trail is most of the value, because the next session has no memory of how a sentence came to be there.

The one document that IS rewritten is `RESUME.md` (see `01_PLANNING_WORKFLOW.md`) — and it is rewritten precisely so that the directives and HANDOFF need not be.

---

## The Manual Is a Design Test

Write the user manual early — before the feature is finished, sometimes before it is started — and read the draft for **strain**, not style.

Anything that takes three paragraphs to explain to a reader is probably a design fault, and it is far cheaper to find while the design is still cheap to change. Prose polish can wait indefinitely; the strain is only visible now.

**How to apply:** when a feature is being specified, write the paragraph that would explain it to a reader. If the paragraph needs caveats, sub-clauses or a second paragraph, that is a finding about the feature. Do not fix it by writing better; raise it as a design question in the directive's open questions.

Worked example from Codex: the manual's page-number chapter would not go down without a caveat — a page is a page *as you have it set up*. That strain was a real rule surfacing (page numbers are the feel; the percentage is the record), so the chapter states it outright instead of apologising. Every other chapter went down in a sentence or two.

This pairs with the paired-intuition rule in `02_DEVELOPMENT_PHILOSOPHY.md`: a failure that recovers by instinct is a paragraph the manual never has to write.

---

## Discussion Is Not Instruction

An owner who thinks out loud has not ruled. *"It feels like a v1.0"*, *"to be fair, that is how they access the library now"*, a question, a piece of context — these are discussion. *"Re-ingesting a book with the same hash silently disregards the new one"* is a ruling.

- **Record findings freely.** Writing what was learned into HANDOFF is almost always right.
- **Move nothing the owner did not move.** Tiers, priorities and scope are the owner's. On Codex a card was re-tiered twice in one conversation on the strength of the assistant's own argument; the owner's reply was *"I have not asked you to move it, I have just discussed around it."*
- **When it could be either, ask in one line.** It costs far less than an edit the owner has to notice and undo.

---

## Do Not Normalise a Deliberate Anomaly

A value outside the known set — a tier that is not on the ladder, a label that matches no column, a number that does not fit the scheme — is **a message, not a mistake**. The owner reached outside the vocabulary because the vocabulary could not say what they meant.

On Codex a card was tiered `v1.5` on a board whose tiers were v1.0 / v1.1 / v1.2 / v2. The assistant mapped it to v1.2 and explained why that was the honest fit. The owner: *"'No v1.5 tier exists' which is why I picked it."* Snapping the value to the nearest category destroyed the signal. The guard now written into the board glossary: *a tier not in the table is deliberate; do not normalise it.*

Meeting such a value, leave it and ask what it means. A confident rationalisation for the mapping is the tell that a decision is being overwritten.

---

## Separate What Is Recorded From What Is Displayed

A recurring class of directive error: a rule about what may be **persisted** quietly decides what may be **shown**, or the reverse.

Codex's form of it: the reading position is recorded as a fraction (it syncs, it survives a font change); the page number is displayed (it is the feel, it is never persisted). Three separate guards written to protect the *record* — "a post-jump position may be stale, do not save it" — also blanked the *display*, because the guard sat upstream of both consumers.

**The directive-level rule:** when specifying a value, say separately what is recorded, what is displayed, and which may be derived from which. When specifying a guard, **name its consumer**. "The position of record" belongs in the save path and nowhere else. "The page number" may not read the position at all if it is not derived from it. A guard that cannot name its consumer is in the wrong place — and a guard on a one-way door (a value baked into an image, a record synced to other devices) is permanent, so its cost lands where the author was not looking.

---

## The Directive Is the Source of Truth

If the directive says X and Claude Code builds Y, one of two things happened:
1. The directive was ambiguous (update the directive to be more explicit, then correct the code)
2. Claude Code made an error (correct the code with a reference to the directive section)

Either way, the directive wins. The answer is never to update the directive to match the code without a deliberate decision that the code is actually right.

---

## Drift Runs Both Ways — Audit It as a Report, Never as a Fix *(Revised 2026-09-04, Icarus)*

The section above assumes the directive is right and the code drifted. Icarus proved, repeatedly, that **the directive is as likely to be the stale one**. In one session (2026-07-29) four false claims were found in the overall directive alone: the watchdog "triggers pause + dialog" (it had not for two weeks); the schema version "v1.5" (actual v1.12, stale through seven bumps); a stop rule "uses the elapsed counter" (the code used wall-clock, with a comment saying why); an editor "for v2" that had shipped six weeks earlier and was recorded as shipped *in the same file's anti-goals*. Elsewhere a chart caption was wrong because the directive prescribed the wrong wording and the code implemented it faithfully; and a colour-verification step the directive called *"OWED, not yet built"* existed as a Debug button nobody had pressed, so the owner believed a critical check was active. *"That can't happen."*

**The owner's rule (2026-07-13): a drift audit is a READ-ONLY report.** Sweep every directive against the code and produce a table — `file:line ↔ directive §`, what each says, and *which side looks authoritative* — then stop. No code edits, no directive edits. The reason is the whole point: **a fix pass silently reconciles by editing whichever side is more convenient**, and some divergences mean the directive is stale, some mean the code is wrong, and each needs a human decision about which. Discuss, then fix. (The sweep fans out well: one read-only sub-agent per directive.)

Three habits that keep the two sides closer between audits:

- **Nothing lands without its directive line updated in the same commit** — the drift discipline this kit already asks for, restated because it was not followed on the day it mattered.
- **A handoff states what is WIRED, not what EXISTS.** A service file that is called from nowhere is indistinguishable, from the directive's side, from a feature we think we have. Grep the type name outside its own file before writing "implemented".
- **When a rule is corrected, name the old wording** (see "Directives Grow…" above), so the correction is findable by someone who only remembers the old version.

**What a session must not do** is trust either side unread. *"Verify directives against code before trusting either"* is the Icarus memory's own phrasing, and it is the honest form of "the directive is the source of truth."
