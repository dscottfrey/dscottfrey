# 05 — Architecture Decisions

How to make, record, and revisit architectural decisions in a way that survives across sessions, across branches, and across months.

---

## Why Architecture Decisions Deserve Special Treatment

Architecture decisions are the choices that are expensive to reverse: technology stack, persistence model, rendering approach, module boundaries, data formats, external dependencies. Getting them wrong costs weeks. Losing track of why they were made costs almost as much.

In AI-assisted development, the risk is compounded: a new Claude Code session starts without memory of previous sessions. If the reasoning behind an architectural decision lives only in a conversation, it is gone. The next session will either blindly follow the outcome without understanding it, or — worse — will "improve" a working solution into something broken because it didn't understand the constraint the original solution was navigating.

The architecture decision record is the defense against this.

---

## Record What Was Rejected, Not Just What Was Chosen

The most important thing to record is not what you chose — it's what you considered and did not choose, and why.

**Wrong:**
> The app uses CSS Columns for pagination.

**Right:**
> **Pagination: CSS Columns vs JavaScript scroll-position estimation**
> 
> Considered: JavaScript measurement of `scrollHeight` to derive page count dynamically.
> 
> Rejected because: content height in WKWebView is not stable at measurement time. Fonts swapping late, images loading asynchronously, and dynamic content can all change the height after the initial measurement, producing incorrect page counts and jumpy chapter transitions. This is the root cause of the pagination bugs seen in the initial implementation.
> 
> Chosen: CSS multi-column layout. The browser's layout engine divides the chapter into columns of exactly viewport dimensions. Page count is `scrollWidth ÷ columnWidth` — an integer the browser provides, not an estimate. Boundaries are deterministic and stable regardless of when measurement occurs.

The rejected option and the reason it was rejected are the most valuable parts. They are what prevent a future developer from "simplifying" the CSS Columns approach back to JavaScript measurement without realizing why that doesn't work.

---

## The Trigger-to-Revisit Pattern

Every significant architectural decision includes a trigger: the specific condition under which the decision should be re-evaluated.

The trigger does two things:
1. Prevents endless second-guessing of a working decision
2. Ensures a decision that should be revisited actually gets revisited

**Format:**
> **Decision:** Custom epub parser rather than ReadiumStreamer.
> **Trigger to revisit:** More than three epub-compatibility workarounds have been added to the custom parser, or a class of epub files is consistently broken in a way that would require substantial additional parsing code to fix.

Without a trigger, decisions either get reconsidered constantly (expensive) or never (which allows technical debt to accumulate past the point where it would have been cheaper to act).

---

## Where Decisions Live

- **In the overall directive:** project-wide decisions (technical stack, dependency policy, development philosophy)
- **In the relevant module directive:** module-specific decisions (pagination approach, data format, API choice)
- **In the open questions section:** decisions that are still open, and decisions that were closed (with ✅ and the resolution)
- **In handoff notes:** decisions to revisit in future sessions, with trigger conditions

Do not let decisions live only in conversation. The moment a decision is made, it goes into the directive.

---

## Cross-Module Decisions

Some architectural decisions affect multiple modules. When this happens:
- The decision lives in the module where it is most central
- Other affected modules cross-reference it by file and section
- When the decision is made or changed, update all affected modules

**Example:** The annotation character offset type (Int vs Double) affected both the Annotation System and the Sync Engine. When it was unified to Int, both directives were updated and cross-referenced.

Cross-module consistency checks should be done before declaring the planning phase complete. Read all directives and look for:
- Data types defined in two places that must match
- Interfaces between modules that make different assumptions
- Settings that are referenced in multiple directives but only defined in one

---

## The Handoff Notes Pattern

Handoff notes are decisions or questions that are deliberately being deferred — not forgotten, but parked. They live in the planning `CLAUDE.md` under a "Handoff Notes" section.

A good handoff note includes:
- **What the note is about** — the decision or question being deferred
- **The current decision** — what was decided for now, and why it stands
- **The trigger to revisit** — what would cause this to be reopened
- **The migration path** — if the current decision is ever reversed, how hard is it to change?

**Example handoff note:**
> **ReadiumNavigator — potential rendering layer**
> 
> The pre-render-to-UIImage architecture was chosen. ReadiumNavigator's rendering pipeline was evaluated and rejected — it constrains the UI layer in ways that conflict with the page curl and interactive text selection design.
> 
> Trigger to revisit: if the pre-render pipeline proves unmaintainable at scale, or if Apple's WebKit snapshot API changes in a way that breaks the architecture.
> 
> Migration path: feasible but significant. The EpubLoader interface is narrow (ParsedEpub struct), so the rendering layer beneath it is swappable. However, adopting ReadiumNavigator would require rebuilding the UIPageViewController and interaction layer.

Handoff notes are not failures or admissions of incompleteness. They are an honest record of decisions that were made carefully and deferred deliberately.

---

## The Addendum Pattern for Experimental Work

When working on an experimental branch, features planned during that branch go in an addendum file — not the main directive.

**Why:** If the branch is killed, the main directive is clean and can be recertified. The addendum survives and can be folded back in if the branch is resumed.

**How:**
1. Create `[NN].1_[MODULE_ADDENDUM].md`
2. Begin with a header explaining its relationship to the parent directive and its status
3. Reference it from the main directive with a brief stub section
4. If the branch survives and the feature ships, fold the addendum back into the main directive and delete the addendum

---

## Questioning Someone Else's Advice

If a different session, a different model, or a different person gives architectural advice that conflicts with what's in the directive:

1. Surface the conflict explicitly — don't silently pick one
2. Understand the reasoning behind both positions
3. Consider whether the conflicting advice has access to context the current directive doesn't reflect (e.g., implementation experience from actually building it)
4. Make a deliberate decision and update the directive

In practice: Claude Code sessions will sometimes implement things differently than planned directives specify. The right response is not to update the directive to match the code — it's to understand why Claude Code chose differently, decide whether that choice is correct, and then update whichever one is wrong.

---

## When to Get a Second Opinion

For significant architectural decisions — especially those that are expensive to reverse — it is worth asking multiple sessions independently, without sharing the first session's reasoning upfront. If two independent sessions reach the same conclusion, you can be more confident. If they diverge, surface both arguments and decide deliberately.

More capable models (e.g., Opus vs Sonnet) tend to reason more carefully about long-term architectural consequences. For high-stakes decisions, a more capable model is worth the cost.

The key discipline: when you get a second opinion, engage with the reasoning, not just the conclusion. "Opus said to use ReadiumNavigator" is useless. Understanding why Opus said it — and whether that reasoning applies to your specific constraints — is what matters.
