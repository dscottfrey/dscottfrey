# Claude Code Best Practices — Starter Kit

A portable playbook for planning and building software projects with Claude Code and Cowork. Distilled from real project experience, not theory.

---

## What Is This

A set of documents and templates that capture how to set up, plan, and run a Claude Code project well. The goal is to not re-learn these lessons on every new project.

This kit is not a tutorial on Claude Code itself. It assumes you know the basics. It is a collection of *patterns* — ways of working that have proven effective.

---

## What Is Here

```
Claude Code Best Practices/
├── README.md                    ← you are here
├── prompt.txt                   ← paste this to start a new workspace session
│
├── 01_PLANNING_WORKFLOW.md      ← how to set up and run the planning layer
├── 02_DEVELOPMENT_PHILOSOPHY.md ← code quality principles that Claude Code must follow
├── 03_DEPENDENCY_FRAMEWORK.md   ← how to evaluate and justify external libraries
├── 04_DIRECTIVE_WRITING.md      ← how to write effective directives
├── 05_ARCHITECTURE_DECISIONS.md ← how to record and revisit architectural choices
│
└── TEMPLATES/
    ├── CLAUDE_PLANNING.md       ← template for the planning-workspace CLAUDE.md
    ├── CLAUDE_BUILD.md          ← template for the Xcode/build-workspace CLAUDE.md
    ├── MODULE_DIRECTIVE.md      ← template for a module directive
    └── ADDENDUM.md              ← template for an experimental-branch addendum
```

## How To Use This Kit

**Starting a new project:**

1. Create a Cowork planning workspace folder
2. Copy `TEMPLATES/CLAUDE_PLANNING.md` → `CLAUDE.md` in that folder, fill it in
3. Create a `Docs/` subfolder
4. Copy `TEMPLATES/MODULE_DIRECTIVE.md` for each module, fill them in
5. When ready to build, create the Xcode project and copy `TEMPLATES/CLAUDE_BUILD.md` → `CLAUDE.md` into the project root, fill it in
6. Copy `Docs/` into the Xcode project root

**Starting a planning session:**
Read `01_PLANNING_WORKFLOW.md` → section "Session Start Ritual."

**Starting a build session:**
Paste `prompt.txt` into the Claude Code terminal.

**When you're about to add a library:**
Read `03_DEPENDENCY_FRAMEWORK.md` first.

**When writing a new directive:**
Read `04_DIRECTIVE_WRITING.md` first.

---

*This kit was assembled from the Codex iOS project (2025–2026). Update it as new patterns emerge.*
