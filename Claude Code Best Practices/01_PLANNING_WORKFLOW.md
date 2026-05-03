# 01 — Planning Workflow

How to set up the two-layer planning and build system and run it session by session.

---

## The Core Idea: Plan Before You Build

The most expensive mistake in AI-assisted development is handing Claude Code a vague goal and letting it fill in the design. You get code quickly, but it reflects Claude's assumptions — not yours. The planning layer exists to capture your decisions before any code is written, so Claude Code is executing a spec, not inventing one.

**The rule:** Nothing gets built until it is specified in a directive. If a decision is not in a directive, it has not been made.

---

## The Two-Workspace System

Every project lives in two separate places with different purposes:

### Layer 1 — Planning Workspace (Cowork)

Where you think, discuss, and decide. Contains:
- `CLAUDE.md` — tells Cowork what this workspace is and how to use it
- `Docs/` — all directive files
- Notes, addenda, and conversation history

This is where you come when you want to explore a question, make a decision, or update the spec. Claude in Cowork reads the files here to understand your project and help you plan.

**No code is written here.** This is a thinking environment.

### Layer 2 — Build Workspace (Xcode project + Claude Code in terminal)

Where code is written. Contains:
- `CLAUDE.md` — tells Claude Code the rules of engagement for this project
- `Docs/` — exact copy of the directive files from Layer 1
- All Swift source files, assets, project configuration

Claude Code reads the `CLAUDE.md` and `Docs/` at the start of every session and uses them as the spec.

**The planning files in Layer 1 are the source of truth.** The copies in Layer 2 are synced from Layer 1. When the spec changes in Layer 1, copy the updated files to Layer 2 before the next build session.

---

## The Two CLAUDE.md Files

They have different audiences and different jobs.

### Planning CLAUDE.md (Layer 1)

Tells Cowork Claude:
- What this workspace is (planning only — no code written here)
- The folder structure and what lives where
- How to work: read relevant directive before discussing, update directive when decisions are made
- Current project status
- What the app is in one paragraph
- Handoff notes from previous sessions

See `TEMPLATES/CLAUDE_PLANNING.md`.

### Build CLAUDE.md (Layer 2)

Tells Claude Code:
- What to read first and in what order
- The four or five most important rules (condensed from the full directive)
- How to interact with the project owner
- Platform, frameworks, dependencies
- Current build status

See `TEMPLATES/CLAUDE_BUILD.md`.

---

## Directive Files

Each major module or concern gets its own directive file in `Docs/`. Number them for reading order:

```
Docs/
├── 00_OVERALL_DIRECTIVE.md    ← read first, every session
├── 01_[MODULE_ONE].md
├── 01.1_[MODULE_ONE_ADDENDUM].md  ← experimental/planned features (if needed)
├── 02_[MODULE_TWO].md
└── ...
```

The overall directive (always `00_`) contains project-wide principles, technical stack, development philosophy, and settings architecture. It is the document every other directive defers to.

See `04_DIRECTIVE_WRITING.md` for how to write directives. See `TEMPLATES/MODULE_DIRECTIVE.md` for the standard structure.

---

## The Addendum Pattern

When working on an experimental branch, features planned during that branch go in an addendum file (`01.1_MODULE_ADDENDUM.md`), not the main directive. The main directive stays clean.

**Why:** If the branch is killed, the main directive can be recertified from the last known-good state. The addendum survives and can be folded back in when the branch is revisited.

The addendum file begins with a header explaining:
- Which directive it extends
- That it contains planned-but-not-built features
- What to do with it if the branch dies

See `TEMPLATES/ADDENDUM.md`.

---

## Session Start Ritual

**Every planning session (Cowork):**
1. Read `CLAUDE.md` in the planning workspace (Cowork reads this automatically)
2. Read `Docs/00_OVERALL_DIRECTIVE.md`
3. Read the relevant module directive before discussing or deciding anything about that module
4. Check handoff notes in `CLAUDE.md` for anything that was left open

**Every build session (Claude Code terminal):**

Paste `prompt.txt` as the opening message. Claude Code will:
1. Read the build `CLAUDE.md`
2. Read `Docs/00_OVERALL_DIRECTIVE.md`
3. Read the relevant module directive
4. Summarize what it understands and what open questions exist
5. Wait for direction before writing any code

Do not skip this ritual. A Claude Code session that starts without reading the directives will make assumptions. The ritual is cheap. The cleanup is expensive.

---

## Session End Ritual

**End of any planning session where directives changed:**
1. Confirm the directive accurately reflects every decision made in the session — nothing left only in the conversation
2. Copy the updated `Docs/` from the planning workspace to the Xcode project root
3. Note in `CLAUDE.md` any handoff items for the next session

**The sync step is mandatory.** If the planning workspace and the build workspace get out of sync, Claude Code will build to the wrong spec.

---

## Using Claude Code — Terminal vs Cowork

Use Claude Code in the terminal (not Cowork) for:
- Extended builds that span many files
- Any session where you want unattended execution
- Work that requires file system access, compilation, or running tests

Use Cowork for:
- Planning and specification
- Reviewing and editing directive files
- Discussions about architecture or design
- Anything where you want a conversation before code is written

**Unattended Claude Code builds:**

For extended builds, run Claude Code with:
```
claude -p "$(cat prompt.txt)" --dangerously-skip-permissions
```

Before doing this, configure `.claude/settings.json` with explicit allow and deny lists to constrain what the unattended session can do. Never run unattended without a deny list.

---

## When Claude Code Goes Wrong

When Claude Code implements something differently than the directive specifies:
1. Identify the specific gap between what was built and what the directive says
2. Update the directive to be more explicit about the requirement (if it was ambiguous)
3. Give Claude Code a correction message that references the directive section by number

The directive is the source of truth. If Claude Code did something different, either the directive was ambiguous (fix the directive) or Claude Code made an error (correct it with a reference to the directive). Either way, the directive wins.

---

## What Stays in Conversation vs What Goes in the Directive

**Conversation:** exploration, questions, options being weighed, things not yet decided

**Directive:** every decision, immediately after it is made

The moment a decision is made in conversation, update the directive. Do not leave decisions in the conversation — conversations are not searchable, not persistent across sessions, and not visible to Claude Code.
