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
├── README.md                                       ← you are here
├── prompt.txt                                      ← paste this to start a new build session
├── prompt_retrofit_build_number_automation.txt     ← paste into Claude Code to add the build-ID system to an existing project
│
├── 01_PLANNING_WORKFLOW.md      ← how to set up and run the planning layer
├── 02_DEVELOPMENT_PHILOSOPHY.md ← code quality principles that Claude Code must follow
├── 03_DEPENDENCY_FRAMEWORK.md   ← how to evaluate and justify external libraries
├── 04_DIRECTIVE_WRITING.md      ← how to write effective directives
├── 05_ARCHITECTURE_DECISIONS.md ← how to record and revisit architectural choices
│
├── HANDOFF.md                   ← running log of future additions and open threads for the kit itself
│
└── TEMPLATES/
    ├── CLAUDE_PLANNING.md            ← template for the planning-workspace CLAUDE.md
    ├── CLAUDE_BUILD.md               ← template for the Xcode/build-workspace CLAUDE.md
    ├── MODULE_DIRECTIVE.md           ← template for a module directive
    ├── ADDENDUM.md                   ← template for an experimental-branch addendum
    └── BUILD_NUMBER_AUTOMATION.md    ← reference script + About-screen code for auto-incrementing build IDs
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

**When you want to add the build-identifier system to an existing project:**
Paste `prompt_retrofit_build_number_automation.txt` into a Claude Code terminal session opened in that project's repo.

**When you spot something the kit should eventually cover but isn't ready to write up yet:**
Add it to `HANDOFF.md` so it isn't lost.

---

*This kit was assembled from the Codex iOS project (2025–2026). Update it as new patterns emerge.*
