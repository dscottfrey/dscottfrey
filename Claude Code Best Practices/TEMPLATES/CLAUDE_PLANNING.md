# [Project Name] — Planning Project

> **Two-workspace variant (historical).** This template is for projects that keep a
> separate Cowork planning workspace with `Docs/` copied into the build project. Codex
> abandoned that model within weeks — the copy step was the failure point, and the real
> rulings were made mid-build anyway. The recommended model is **one repo, one terminal**:
> `Docs/`, the assistant's memory and the skills all live in the project repository,
> `Docs/RESUME.md` is the start-here file, and there is no sync step. See
> `01_PLANNING_WORKFLOW.md` — "One Repo, One Terminal". Use this file only if a separate
> planning environment is a deliberate choice, and make the sync step a script, not a
> reminder.
>
> *(Revised 2026-09-04, Icarus: a second project seeded this way dropped the copy step
> just as fast; its overall directive still contains the sentence "`Docs/` is copied
> wholesale from the planning workspace before any build session", which no session has
> performed since the first week. Two projects, one outcome.)*

## What This Folder Is

This is the **planning workspace** for [Project Name]. Work here consists of discussing features, making design decisions, and maintaining the directive files that specify how the app should be built.

This is NOT where code is written. Code lives in the [Xcode / other] project on [developer's machine].

---

## Folder Structure

```
[Project Name] Planning/
├── CLAUDE.md                          ← you are here (planning context)
└── Xcode Project Files/               ← copy this entire folder's contents to the project root when updated
    ├── CLAUDE.md                      ← Claude Code reads this when building in the terminal
    └── Docs/
        ├── 00_OVERALL_DIRECTIVE.md    ← read this first, every session
        ├── 01_[MODULE_ONE].md
        ├── 02_[MODULE_TWO].md
        └── ...
```

**The directive files live in `[Project Files]/Docs/`.** That is where they are edited. Do not create duplicate copies elsewhere.

---

## How to Work Here

1. **At the start of every session:** read `[Project Files]/Docs/00_OVERALL_DIRECTIVE.md` for project context. Read the relevant module directive before discussing or editing that module.

2. **When making decisions:** update the relevant directive file immediately. Do not leave decisions in the conversation without recording them in the directive.

3. **At the end of every session where any directive was changed:** remind [developer name] to copy the contents of `[Project Files]/` to the project root on their machine, so the build context stays in sync with the planning context. The project is at `[path/to/project]`.

---

## Current Project Status

**Planning:** [Complete / In progress]  
**Building:** [Not started / In progress / Module X complete]  
**Next step:** [What happens next]

---

## The App in One Paragraph

[A tight one-paragraph description of what the app is, what problem it solves, and what makes it distinctive. This is the north star — when a decision is ambiguous, refer back to this.]

---

## Owner Accessibility Notes

Accessibility requirements driven by the project owner. These apply to both how Claude communicates with the owner during sessions *and* to color choices for the app itself.

The owner has Protanomaly. When providing color-coded information, do not rely on the distinction between Purple/Blue, Green/Brown, or Orange/Green. Use high-contrast labels, distinct icons, or textures instead of color alone.

The same pairs must also be avoided when planning or proposing colors for the app itself — brand palette, status indicators, chart series, accents. The owner reviews every design and uses every build, so a color scheme that visually collapses these pairs for the owner makes both daily use and design review harder. The owner's apps are primarily for the owner's own use; broader accessibility is also a goal but the owner's specific needs take priority when they conflict.

[This is in addition to, not a replacement for, the universal redundancy rule in `02_DEVELOPMENT_PHILOSOPHY.md` "Color Is Never the Sole Signal" — both apply to every project. Edit or remove the owner-specific guidance above based on the actual project owner.]

---

## Handoff Notes

[Things to revisit in future planning sessions — decisions that were closed for now but warrant a second look as the build matures. Include: what the note is about, the current decision, the trigger to revisit, and the migration path if applicable.]
