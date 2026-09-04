# [Project] — Release Notes

*Template added 2026-09-04, Icarus. Generalised from `Docs/RELEASE_NOTES.md` in the
Icarus project: the running record of what changed between one build the customer
actually ran and the next. Copy to `Docs/RELEASE_NOTES.md`. The customer-facing copy
that travels with each build is a separate plain-text file written from the closed
section (see `TEMPLATES/RELEASE_CHECKLIST.md` §F, step 4).*

## What this file is

The running record of everything that changed between one build the customer
actually ran and the next one they will run. Entries accumulate here as work lands;
when the owner says a build is shipping, the "Unreleased" section below is closed
off, stamped with its version and date, and a fresh "Unreleased" section is started
above it.

Written for the customer, not for developers — plain English first, the technical
reference in brackets after. Anything the customer can *observe* leads; internal
work they can't see is grouped at the bottom under "Under the hood".

**Rule: nothing goes in here that isn't true yet.** An entry means the change is
written and builds. Where something is written but not yet proven on a real run, it
says so. Specified-but-unbuilt work belongs in a handoff, not here.

**Rule: state what the bench cannot prove.** [Name what the development machine
lacks — Icarus: no projectors, no lamps, no sphere, no UPS.] Anything touching those
ships unverified; say so, and say what *was* tested. A note that implies more
confidence than exists is worse than no note.

**Rule: lead with whatever the customer will SEE that they did not ask for.** A
change in visible behaviour is alarming when it arrives unexplained and reassuring
when it arrives described.

## Versioning

Standard three-part version numbers — `MAJOR.MINOR.PATCH`:

| Part | Increment when | Example |
|---|---|---|
| **PATCH** — 1.0.**1** | Bug fixes and speed-ups. Nothing the customer does changes; existing data files stay readable. | A crash fix, or a slow screen made fast |
| **MINOR** — 1.**1**.0 | New capability, or a change the customer will notice, that doesn't break existing data. | A new column added to the end of a data file |
| **MAJOR** — **2**.0.0 | A feature release — a significant new capability or product milestone. The owner's call, never automatic. | — |

**One bump per shipped build.** The version moves once per release, by the largest
increment the release earns — never once per fix, and never scaled to how many
things changed. The same rule governs any data-file format version: a build that
alters the layout in three ways still takes the format from 10 to 11, not to 13.

**Two different binaries never share a version number.** The customer keeps every
build side by side and picks by name, usually when something has gone wrong. Bump
for a one-line fix.

**A compatibility break does not by itself force a MAJOR.** It ships as a minor
release carrying an explicit migration note; the break is communicated to the
customer, just not through the version number. (Owner direction, Icarus,
2026-07-30.)

**The ORDER of the shipping steps** is `TEMPLATES/RELEASE_CHECKLIST.md` §F — commit,
bump, close `Unreleased`, write the customer notes, and only then build. The rules
above were once followed in the wrong order and a release went out carrying the
previous version number and no notes.

The version shown in the About panel is this number plus the automatic build stamp
and the short git SHA — so any build can always be traced back to exactly what was
in it.

---

## Unreleased

Nothing yet — this section accumulates as work lands after [last version].

---

## [X.Y.Z] — [YYYY-MM-DD]

**Baseline: build [stamp], version [previous]** — the build running when [what
prompted this release]. Every change below came after it.

**Why this release exists.** [One paragraph. What happened, what the customer
experienced, what was the app's responsibility and what was not.]

### [Headline the customer will notice — in their words]

[What changed, what they will see, what they must do differently. If it is not yet
proven on a real run, say so here.]

### [Next headline]

…

### Under the hood

[Internal work grouped here: what changed, in one line each, with the technical
reference in brackets. Schema or file-format version changes are stated explicitly
— "no schema change" is worth a line of its own.]

### Not yet proven on a real run

[The list. Each with the log line or observation that will confirm it.]
