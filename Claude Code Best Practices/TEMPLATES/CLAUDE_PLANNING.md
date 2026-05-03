# [Project Name] — Planning Project

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

## Handoff Notes

[Things to revisit in future planning sessions — decisions that were closed for now but warrant a second look as the build matures. Include: what the note is about, the current decision, the trigger to revisit, and the migration path if applicable.]
