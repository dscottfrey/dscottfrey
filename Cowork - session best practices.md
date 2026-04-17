# Cowork — Session Best Practices

How to run productive Claude Cowork sessions on coding projects without burning tokens or losing context between chats. Built around a simple pattern: one folder per app, a short `HANDOFF.md` in each folder, and a repeatable opening/closing ritual.

See also: `Code/README.md` (system-wide folder conventions) and `Code/_shared/SESSION_PROMPTS.md` (copy/paste prompt library).

---

## Pinned — Cowork project instructions (paste once)

When creating a new Cowork project via **"Use an existing folder on your computer"** (or editing an existing project's settings), paste this block into the project's **Instructions** field. It runs automatically on every chat inside that project — you never retype it.

Replace the app name and adjust the "local-only" line depending on whether the app is a GitHub repo or intentionally local.

```
This project is <AppName>. <Delete one: "It is intentionally local-only and must never be committed to GitHub or run any git commands." | "It lives at github.com/dscottfrey/<repo>.">

At the start of every chat, read HANDOFF.md, DECISIONS.md, and CLAUDE.md in the attached folder before responding to anything else. Summarize the current state and the proposed next step, and wait for my go-ahead before making any changes.

Follow the session conventions in /Users/scott/Documents/Code/README.md.

At the end of every chat — when I say "wrap up," "we're done," or anything similar — update HANDOFF.md with the new current state and next steps, and append a dated entry to DECISIONS.md if any meaningful architectural choice was made. For GitHub-tracked projects, stage and commit the changes (but never push without my go-ahead). If I seem to be winding down without saying so, remind me.
```

Put this in the project instructions **once**. It applies to every chat in the project forever.

---

## The opening ritual

Every new chat in a Cowork project should start with one short message that does three things: confirm the task, ask for a plan, and bar edits until you approve.

Default template:

> What's the top next step from HANDOFF? Confirm it's still right, propose a plan, and wait for my go-ahead before editing.

If you want to work on something *different* from what HANDOFF lists as next:

> Skip HANDOFF's listed next steps — I want to <specific task>. Read whatever files that touches, propose a plan, no edits yet.

That's the whole opening move. Don't paste old transcripts. Don't re-attach files. With the project instructions pinned and the folder already attached, HANDOFF + DECISIONS + CLAUDE.md gives Claude full situational awareness for roughly 500–1,000 tokens — tiny, and Claude will only open the specific code files the plan actually needs.

**Why "no edits yet" matters.** It prevents the common failure mode where Claude enthusiastically refactors something you didn't ask it to touch. You get a plan, you approve (or adjust), *then* work starts.

---

## When to start a fresh chat vs. stay in the same one

Start a fresh chat when:

- The current chat feels sluggish or long.
- You're switching tasks within the same project.
- The previous session crashed.

Stay in the current chat when:

- You're mid-thought on a tight, narrow task.
- Tokens are still healthy.

**One-task-per-chat is the north star.** A chat titled "threading refactor" is more useful than "IcarusVirtualHub Apr 17," because next week you can still find the former by name. HANDOFF.md + DECISIONS.md are what carry context across chats — not the chat history itself.

---

## Mid-session habits

- **Surface important notes.** If something significant comes up that isn't part of the current task, say *"note this for HANDOFF"* so it doesn't evaporate at the end of the session.
- **Interrupt dead ends.** If Claude starts spinning, say *"stop, summarize what we tried, and reset."*
- **Wrap up early if needed.** If the chat is about to get long before the task finishes, wrap up with a mid-task HANDOFF and start fresh. Cheaper than letting a bloated chat degrade.
- **Don't re-paste old transcripts.** The handoff has already restored context. Pasting old chat content wastes tokens and usually adds confusion.

---

## Ending the session

When you say any of *"we're done,"* *"wrap up,"* *"let's stop here,"* or similar, Claude should automatically:

1. Update `HANDOFF.md` with the new current state, what was completed this session, and the next 1–3 steps.
2. Append a dated entry to `DECISIONS.md` if any meaningful architectural decision was made, using the format in `Code/README.md`.
3. Optionally archive the previous HANDOFF into `sessions/HANDOFF-YYYY-MM-DD.md` before overwriting.
4. For GitHub-tracked projects: stage and commit the changes with a concise message (e.g. `feat: add login flow + update handoff`). **Never push without explicit go-ahead** — you review first.
5. For local-only projects (e.g. IcarusVirtualHub): just the file updates, no git commands.

If Claude doesn't offer this as the session winds down, prompt it.

---

## HANDOFF, DECISIONS, and CLAUDE.md — how they differ

Three files can coexist in an app's folder, each with a distinct job:

- **`CLAUDE.md`** — *stable project conventions.* Build commands, file layout, SDK quirks, house style. Rarely changes session-to-session. Think of it as the project's README for Claude.
- **`HANDOFF.md`** — *volatile "where are we right now."* Current state, recent work, next steps, open questions. **Rewritten at the end of every session.** Under ~500 words.
- **`DECISIONS.md`** — *append-only architectural log.* One dated entry per meaningful choice, with context and reasoning. Never rewrite past entries; only add new ones.

Claude should read all three at the start of each chat. Only HANDOFF and DECISIONS get updated at session end.

### DECISIONS.md entry format

```
## YYYY-MM-DD — <short title>
**Decision:** <what was chosen>
**Context:** <why this came up>
**Alternatives considered:** <what else was on the table>
**Why this:** <reasoning>
```

---

## Importing an old chat into this system

If you have a past chat that predates this workflow:

1. In the old chat, paste the **"Importing an existing thread"** prompt from `Code/_shared/SESSION_PROMPTS.md`. It asks Claude to produce two labeled markdown blocks — one for `HANDOFF.md`, one for `DECISIONS.md`.
2. Save those blocks into the app's folder as `HANDOFF.md` and `DECISIONS.md`.
3. Create a new Cowork project via **"Use an existing folder on your computer,"** point it at that folder, and paste the pinned project instructions from the top of this doc.

If the old chat has crashed or won't open: the transcript is still on disk. A new Cowork session can often read it directly via the session transcript tools and produce the handoff files without needing the old chat's UI.

---

## Token hygiene

- `HANDOFF.md` stays under ~500 words. It's a pointer, not an archive.
- Don't re-read the entire codebase on resume — read HANDOFF + whatever the next step touches.
- Start a fresh thread per focused work unit rather than stretching one giant thread.
- When a thread starts getting slow or long, that's the signal to wrap up and restart.
