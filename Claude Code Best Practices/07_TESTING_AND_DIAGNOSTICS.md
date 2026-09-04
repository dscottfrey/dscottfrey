# 07 — Testing and Diagnostics

How a project verifies what it built, runs a device-test round without losing the thread, diagnoses a fault without guessing, and ships the instruments that make a tester's log worth reading.

The kit's `HANDOFF.md` carried "Testing Strategy" and "Error Handling and Logging Conventions" as uncovered topics, each with the trigger *"first project that ships to real users"* / *"first project where logs become important."* The Codex iOS project met both in August 2026. This file is what it learned. Every rule here cost at least one build-and-test round to learn; several cost four.

Files 01–05 are platform-agnostic. This file is written from an Apple-platform project and the compile recipes are Swift-specific; the disciplines are not.

**Revised 2026-09-04, Icarus.** The Icarus project — same owner, same sandbox, a macOS instrument with real hardware and a customer who reads the data — confirmed most of this file and added what a tester-less, unattended, data-producing app needs: verify from the data on disk, list what shipped unproven, write findings for the customer from the instrument's own files, and read the operating system's own diagnostics.

---

## What the Assistant Can and Cannot Verify

Claude Code's sandbox on this project **cannot run `xcodebuild`** — Swift Package Manager resolution needs write access outside the sandbox and fails with `permissionDenied` however the caches are redirected. So any change larger than a few lines ships to the owner unverified by a full compiler. **The owner is the first person to build it.**

That does not mean nothing can be checked. Three tiers exist, and it matters which one a claim rests on:

### Tier 1 — full type-checking against the iOS SDK

Much stronger than a parse: it catches wrong types, bad argument labels, and dangling cross-file references.

```sh
SWIFTC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
SDK=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
"$SWIFTC" -typecheck -sdk "$SDK" -target arm64-apple-ios17.0 \
    -module-cache-path "$TMPDIR/swiftmc-ios" <files…>
```

Three details make it work, and it fails confusingly without each: call `swiftc` by full path (`xcrun` cannot write its cache), pass the SDK explicitly (otherwise "unable to load standard library"), and redirect the module cache into `$TMPDIR` (otherwise "Operation not permitted"). Pass every file the code references, or its symbols come back undefined.

**Limit:** `@Model` will not expand in this environment — any file touching a SwiftData model fails with *"external macro implementation type 'SwiftDataMacros.PersistentModelMacro' could not be found"* and takes its dependents down with it. Read the errors: if the only ones are the macro's, the file under test produced none of its own.

### Tier 2 — compile AND RUN pure logic against the macOS SDK

Stronger still, because it tests behaviour. Copy the function verbatim into a scratch file with a table of cases, build against the macOS SDK, run it:

```sh
SWIFTC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
SDKM=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
"$SWIFTC" -sdk "$SDKM" -module-cache-path "$TMPDIR/swiftmc-mac" -o probe probe.swift && ./probe
```

Use it for anything that is just Foundation and arithmetic — string escaping, parsers, formatters, ordering, boundary maths. On Codex it proved a CSV export's RFC 4180 escaping against six real cases in seconds. It cannot touch UIKit, SwiftUI, SwiftData or a third-party navigator — but the bugs in those files are usually in the pure part anyway.

### Tier 3 — `swiftc -parse`, which is syntax only

**Never call a parse "verification."** It cannot see wrong types, wrong argument labels, or wrong argument *count*. A "parse-clean" change broke a build with *"Extra arguments at positions #2, #3, #4, #5"*; a later parse-clean edit hid three type errors left by a rename. Say *"parse-clean, which cannot catch type or arity errors."*

### Tier 0 — read what the app wrote to disk *(Revised 2026-09-04, Icarus)*

Stronger than any compile for the question that matters — *did it do the right thing?* The sandbox that cannot run `xcodebuild` (Icarus: the out-of-process build service is denied filesystem access, same as Codex) **can read every data file, log and SQLite store the app produces.** Icarus's five-day-run analysis came from a 412,258-line log and six data files, parsed in the sandbox; the fault-column encoding was proven by round-tripping all 32,768 values through a scratch binary; a 42,606-row store repair was verified against a copy of the lab's real database. None of it needed a build.

**So verify from disk yourself.** The owner, on 2026-07-13, after being asked three times to open files the assistant could read: rightly angry. Ask the owner only for what the assistant genuinely cannot observe — the screen, a crash, the hardware, an action only they can take. Everything file- or database-observable, the assistant reads and reports.

**One trap:** know how the rows were written before querying them. Rows a rebuild creates may carry only scalar keys and a null relationship, so a join on the relationship returns zero and looks exactly like a silent import failure. The assistant raised that false alarm on the owner (2026-07-30). Read the writer before reading the table.

### The claim discipline

- **"Done" from source alone is a claim about code, not about the app.** Say which tier the claim rests on.
- **"Implemented" is not "verified", and "exists" is not "wired" *(Revised 2026-09-04, Icarus)*.** A colour-verification service existed, worked, and was called from exactly one Debug button nobody had pressed on the real rig; the directive implied it was active; the owner believed a critical check was running. A second service was called from nowhere at all. *"That can't happen."* Before claiming a capability, grep the type name outside its own file; a handoff lists what is wired and what has been proven on the real thing, separately.
- **The checkbox rule:** a card, ticket or task is ticked off only after the owner has confirmed the work on a device — never on having written the code. The one fact that is genuinely the owner's is whether a written thing *works on the glass*.
- **Never delete a range located by a string that is not unique.** A one-line instrument was removed by finding an anchor that occurred eight times in the file; the edit deleted 199 lines, parsed clean, committed clean, and was caught by the owner's build with 29 errors. Before any ranged delete, `grep -c` the anchor; if it is not 1, cut by line number and assert the boundary lines by content on both ends. Then `git diff | grep '^-'` and read what is going. And prefer the smaller cut — the instrument was inside an `#if DEBUG … #endif` and deleting exactly that block needed no surrounding context at all.

---

## The Unit-Test Net

**The owner runs the test target (⌘U in Xcode) before every build that is handed over.** No exceptions. It is the one compile-and-run step the assistant cannot do and the owner can do in one keystroke. On Codex the net was 51 tests by the time of the first sync build; it grows whenever a rule becomes stable enough to pin.

**Use the owner's vocabulary, exactly.** On Codex:

| The owner says | It means |
|---|---|
| **unit tests** | ⌘U — the test target, run before any handed build |
| **regression tests** | scripted device runs (robot page-turning against real books, then the assistant's log greps) that the owner performs exactly as instructed, one step at a time |

The assistant once second-guessed "doing unit tests" and talked past it. The vocabulary is the owner's; take it at face value. When regression testing, give one concrete step at a time (see `08_WORKING_WITH_THE_OWNER.md`) and read the logs yourself.

What goes in the net: pure logic that has a settled rule (page-number parity, TOC resolution, CSV escaping, merge precedence). What does not: anything that needs the glass. A test that drives the view layer is expensive and flaky; a test of an extracted logic type is cheap and honest.

---

## The Test Round Protocol

A test round is OPEN from the moment a build is handed to the owner until his complete report is in. While it is open:

### One build in flight, per device, per round

**Hand over a build → freeze.** No commits, no edits to the code path under test, no newer build, no revised instructions until the full report arrives. The owner tests and types slowly and cannot watch the screen while typing; a build that advances under him means his report and the assistant's expectations describe different binaries. On Codex that burned three debugging rounds on "which build is this?" in one afternoon and ended in capitals.

**Why:** his test report is the ONLY ground truth in the loop. Invalidating the binary mid-round destroys the report's meaning and forces log archaeology to reconstruct what ran.

**Refinement:** the freeze is per DEVICE and per ROUND, not per tree. With one device running an overnight soak on one build, other work proceeds and ships to a second device — the code path under test stays untouched, and the stamp tells the logs apart.

If a fix becomes obvious mid-round, write it down in the scratchpad or the handoff file — not into the tree.

### The stamp identifies the binary, and the assistant checks it

Every build carries a stamp line the log prints at launch (Codex: `[curl-build] stamp: <name>`; see `02_DEVELOPMENT_PHILOSOPHY.md` "Every Build Is Identifiable" for the automated version, and note that Codex maintained its stamp by hand and had it go stale twice). **The assistant reads the stamp in every log before interpreting anything.**

The owner does not read logs. His words: *"you keep saying things like 'Stamp should read TAPS2', but I have no idea where it would read that."* And, asked to "send the hitch line": *"I have no idea how."* The division of labour:

| The owner | The assistant |
|---|---|
| reads the book, notices what is wrong ON SCREEN, screenshots it | reads the log file from the shared folder |

Never tell the owner what the log should say. Never ask him to paste or find a line.

### The pre-test brief has exactly three lists

With every build request:

1. **What to DO** — the steps, in his terms.
2. **What he will SEE** — the visible symptom, if any, that he is checking for.
3. **What is KNOWN-BROKEN** — unbuilt, deliberately unfinished, or already logged — so he does not report it.

The third list is not optional and it is not buried in a doc. The owner: *"you need to be more clear about what I should not report on then. I can only look at the whole thing."* He cannot see the seams; a half-finished feature and a broken one look identical from the device. Without the list he either reports known gaps (wasted effort) or assumes a real defect is a known gap and stays quiet — and the second failure is the expensive one. Keep the list current; an item stays on it only while it is actually still unbuilt.

**Never put log strings to watch for in the brief.** Not grep targets, not "shout if you see X in the console." The one exception is a symptom he can see WITHOUT the log which happens to also have a log signature — describe the visible symptom, not the line.

### The fourth list — what shipped unproven *(Revised 2026-09-04, Icarus)*

On a project with no testers the dominant state of the tree is **built-not-compiled**: written in the sandbox, never seen a compiler, waiting for the owner. When a build does go out, some of it will have compiled and never run. Say which. Icarus's 2026-07-30 handoff listed five such changes in the shipped build, the riskiest first (a new data-file column that, if its count disagreed with the header, would make the reader silently drop every row), with the one short run that would exercise all five. Its release notes carry the same rule for the customer: *"nothing goes in here that isn't true yet"* — an entry means written and building; where it is not yet proven on a real run, it says so; and the notes **state plainly what the bench cannot prove** (*"the dev machine has no projectors, no lamps, no sphere and no UPS, so anything touching them ships unverified"*). A note that implies more confidence than exists is worse than no note.

### The bench is not the rig *(Revised 2026-09-04, Icarus)*

Three ways Icarus's dev machine differed from the lab's, each of which produced a wrong conclusion once: a different OS major version; a built-in microphone (so a "camera/mic in use" flag fires on dev data and cannot fire on the lab's Mac mini); and one experiment in the database where the lab had several — the crash-recovery classifier took the *first* in-progress record from an unsorted fetch, which was correct on the bench and arbitrary on the rig. **Test with the production cardinality**, and do not conclude the rig's behaviour from the bench for anything that touches hardware or the OS.

**And let the customer yank a cable.** The lab's deliberate mid-run sensor unplug (2026-07-26) and mid-cycle probe pull (2026-07-16) found two recording bugs no bench test had — a dropout written as a zero, and a bay that lost its sensor part-way through a cycle committed one sample of five marked healthy. A yanked cable is a test the assistant cannot run and should ask for.

### A wrong prediction is never reclassified as premature judgment

"You are judging prematurely" is only honest when the gap was *known and unstated*. If the assistant predicted something would work and it did not, that is a wrong prediction — say so plainly. Reclassifying it as a known gap after the fact rewrites what happened, and the owner notices.

### Batch the small stuff into one build

The scarce resource is the owner's attention, not the assistant's time. Every build-and-confirm round costs him a compile, an install, a reading session and a written report. Spending one on "two dead buttons on the empty shelf" is a bad trade — the change cannot plausibly break anything and the round costs the same as one that could.

For work that is small, low blast-radius, and needs no ruling: do the whole pile unattended, then hand over ONE build with a checklist. Conditions, none optional:

- **Genuinely independent** — no two items touching the same file or subsystem, so a break is attributable by inspection.
- **One commit per item**, so any one can be reverted alone. With no local compiler, this is the only recovery route.
- **Nothing needing the owner's judgment** goes in the pile.
- **Anything touching identity, position, the core rendering path or sync is NOT small**, whatever its size label. Those get their own round.

This does not contradict one-build-in-flight. A pile is still one build in flight; it just carries more.

### The pause is the work window

A principle from Codex's page-turn machinery that generalises to any interactive surface: **the moment of interaction never computes; it only hands over what is already proven ready.** Everything expensive — verification, repair, re-shoots, cache fills — happens in the idle time between interactions, where the main thread is free and there are tens of seconds to spare. A user-visible cost that could have been paid in the pause is a bug.

**Failures are hidden, not shown, and logged.** A problem the machinery can repair silently must never reach the screen; what reaches the user is only what could not be repaired, and then it is labelled honestly, never blank. **The log is the product of this:** a session that felt problem-free still contains every silent repair, and that log is the next round's input for inefficiency hunting. The background error logging is not debris. It stays.

---

## Diagnosis Discipline

The pattern of every good day on Codex: build an instrument and read it, rather than reason about what is probably happening. The pattern of every bad day: a confident sentence with nothing measured behind it.

### Instrument before theorising

When a fault cannot be explained from the evidence, **add the instrument — do not reason harder.** Three confident, plausible causes for a blank page number were reasoned out, written up, and all three died on inspection; one added log line then named the real cause on its first run. Roughly an hour of inference lost against ten minutes of instrumenting.

The deeper finding was that **the existing log could not answer the question at all** — the instrument named the reason but not the moment. If the log cannot settle the question, the missing line IS the bug. Put instruments on the failure path so they cost nothing when healthy; then the honest answer to "do I have to go slower?" is no.

### Admit ignorance

*"Admitting ignorance for a second beats being confidently wrong for an hour."* The owner's response: *"you realise you have summed up the problem with an LLM in one sentence. That is exactly what I am trying to get you to always do."*

**The tell is checkable: a confident sentence with nothing measured behind it — especially in a code comment**, because a comment is where a guess gets permanently promoted to a fact and read as one by the next session. A cache-comparison threshold shipped with the comment *"two pages of prose are still wildly apart at sixty-four cells."* That reads like a measurement. It was a guess, wrong by ~4×, and the gate fired on every capture — a whole build round lost. *"I'm guessing 8; if this fires constantly the guess was wrong"* would have cost nothing.

In practice: mark guesses as guesses, in the reply AND in the comment; give the number that would prove the guess wrong; prefer "here is what would tell us" over "here is what I think it is."

### Ask for a picture — and name exactly what to capture

The assistant cannot see the app, the board, or the device. Reasoning about what a screen looks like is guessing dressed as analysis. The owner can produce a screenshot in seconds and does so willingly. Two chains of reasoning died to one screenshot each in a single day: a note-length limit asserted from one cropped view (a full screenshot gave two data points fourteen characters apart and pinned the real limit), and a layout asked about in words twice (one screenshot answered it and corrected the question).

**Name exactly what to capture and in what state.** A vague "send a screenshot" wastes the round too. If the picture would settle it, not having the picture IS the blocker.

**For tuning questions, ask for a matched pair** — the reference app doing the exact drag, and yours doing the same drag — BEFORE picking a default, not after the default is reported wrong. Name the direction, start point and distance so the pair is genuinely comparable. The line: comparisons for *tuning* (how much, how dark, how fast), the project's own capture plus the code for *bug-fixing*. Reasoning was reliably good at explaining *why* something looked wrong once a capture showed it, and reliably bad at *predicting* what would look right. Derive freely once you can see the symptom; get a capture before choosing a value.

### Ask the thing, not its description

Six builds on one fault, three failing identically, each decided from a number that DESCRIBED the page instead of from the page: a navigator's reported location (withheld while it was busy), its viewport arithmetic (bookkeeping about the document, not the screen), and the same viewport again to check a fix that had been made from OUTSIDE it — so it was never told. The fix had moved the page; the viewport said it had not; the assistant believed the viewport and reported failure.

**A model can be right about itself and wrong about the glass.** The two builds that made progress both asked something that cannot lie: the DOM's own geometry (`scrollWidth, clientWidth, scrollLeft`), and the screenshot compared against the previous one. Before spending a build on a measurement, ask: *could this number be right about the model and wrong about the screen?* If yes, find the witness that cannot be — for anything visible, the pixels or the DOM.

### The user's ordering beats the log

The owner: *"I let go of the curl and it snapped back (correctly) then the page turned."* Two events. The log showed one release. The assistant answered "that is not a bug, it is your own ruling" — and was wrong. The "snap-back" was a frozen frame and the "then" was the settle finally running eight seconds later, because a selection session had been flushing a cache on the main thread. The log could not show that; only a person watching the glass could.

**A log records decisions, not what reached the screen.** Between a correct decision and a correct-looking result sit the frames, and nothing in the log knows whether they arrived. When the owner's account and the log disagree, the log is incomplete — go find the missing signal; do not explain the log back to him. Sequence words — "then", "after" — are data. "Working as designed" is only valid when the log accounts for *everything* he describes, including the order.

### Never correct on a lagging signal

A self-correcting anchor read the viewport's page, compared with the target, and stepped off the difference. It condemned itself in one test: stepped −1 from page 2 and landed on page 0. The reading was stale — the position report travels JS → animation frame → Swift, and with the main thread blocked it never arrived, so "two consecutive equal reads" meant *nothing has updated yet*, not *settled*.

**A signal that degrades under load is unusable for a correction that is only needed under load.** Use it to REFUSE and retry — never to decide a move. Refusing is safe when the reading is wrong; acting is not. Every live report from a rendering engine is fine as *metadata* and dangerous as a *verdict*.

### Cross-check hardest when most confident

Reading a dependency's compiled source — the best evidence available — the assistant found a branch as a function's first line and asserted a mechanism, a protection, and a derivable signal on it. All three wrong: the function's only caller ran solely when that branch could not be taken. **The branch was unreachable.** One `grep -n` for the call site settled it, minutes from being built on.

This is not covered by "admit ignorance" or "instrument first": there was real evidence, reasoned from carefully, and the answer was wrong anyway. **A well-evidenced wrong answer is the kind that survives**, because it argues well and nothing about it feels like a guess. So treat confidence itself as the signal to seek an independent check, precisely when it feels unnecessary:

- **Read the call site before believing the branch.**
- Ask what single command would falsify the claim, and run *that*, not another confirming read.
- **Use a second party** with different evidence and different blind spots (Codex uses a separate research bot with web search); give it the falsifiable version of a claim, not the persuasive one.
- **Tag the evidence class in load-bearing sentences** — `[source]` (compiled checkout), `[log]`, `[device]`, `[public]`, `[inferred]`. A conclusion is never stronger than its weakest tag, and `[inferred]` alone never grounds a build decision. It works where "be careful" does not because it makes the inflation visible at the point of writing.
- **Say the withdrawal plainly.** The owner needs to know which sentence just stopped being true; a quiet correction is worse than the error.

### A witness nothing acts on is unfinished

Codex built an OCR check that compared the rendered page against the text the app believed was on it. Its first version merely wrote a panic record on mismatch. The owner's ruling: what the reader is reading RIGHT NOW is the source of truth — on a mismatch the check must **refuse the photo, re-photograph, and realign the register** from the reader's actual words. A thermometer is not a fix.

Two lessons. First, when checking "does it exist," check the CONSEQUENCE, not just the instrument; do not cite "instrument first" to mean "instrument only." Second, **a bandaid that acts is retired once it stops firing** — drop it to log-only when the log shows it consistently agreeing, then off. Its retirement is the proof that the underlying labels are right. (Its first clean run: 251 turns, 0 realigned, 8 firings all on genuinely unreadable display-face pages.)

### Test untethered, not from Xcode

Two faults in one evening turned out to be the debug rig, not the app. A device with an Xcode debug session attached — cable OR Wi-Fi — does not auto-lock, so "the screen never sleeps" was the debugger. And Xcode itself ran out of memory under the console stream and had to be quit.

**Launch from the Home screen with no debug session, and read the file log afterwards.** It is complete on its own. What is lost is only system chatter that never reached the file and never answered a question. This also makes memory readings trustworthy: a debugger-attached process has different memory behaviour and different jetsam limits, so footprint measured under Xcode does not predict the kills that happen in real use — and the kills are the ordinary path.

**Two more from Icarus, on macOS *(Revised 2026-09-04, Icarus)*:** never test crash recovery under the debugger — force-quitting a debugged run leaves a zombie (windows still painted, process gone from the app list) that is `debugserver` holding the process, not a bug; build the `.app`, run it directly, and simulate the crash with `kill -9`. And an Xcode run can register the DerivedData bundle as a login item, so anything involving launch-at-login is tested from an installed copy.

### Measure before blaming — and label what is an estimate *(Revised 2026-09-04, Icarus)*

When the lab Mac filled its disk (2026-07-30), the assistant nearly blamed the app twice — first the chart images it sends by message, then filesystem snapshots — before measuring: a 64 GB runaway search index, nothing to do with the app. When six temperature probes read −273 °C, the assistant asserted *"reseating fixed the physical problem"* and *"open circuit"* as facts and sent the owner rewiring a terminal block; the bug was two missing calls in the app's own code, found by reading the SDK source. Both are the Codex rule again, from the other side: **a diagnosis not read from source or measured from the thing is a guess, and is said as one** — *"I'm guessing; here is what would confirm it."*

Two refinements Icarus adds:

- **An estimate wearing a constant's clothing is still an estimate.** Icarus's per-cycle overhead figures were measured across 63,909 screen visits — on a build ten hours older than two performance fixes that targeted much of that overhead. They went into the code as constants, labelled in the handoff as estimates until a run on the current build re-measured them. The measurement's *provenance* (which build, which run) is part of the number.
- **A recollection that is not in any document is unconfirmed.** The owner recalled a sensor rate of "4 Hz"; the only rate on record anywhere in the repo was "maximum 20 Hz", and neither matched the measured read cost. Recorded as unconfirmed rather than adopted or argued.

And a **dead end is recorded so it is not retried**: the assistant proposed instrumenting the sensor reads with a stopwatch; decomposing timings already in the log answered the question (reads are sub-millisecond; the whole overhead is the screen change). The handoff says so, with the numbers.

---

## Diagnostics That Ship

The instruments above are only useful if they reach the assistant from a tester's device. This is how Codex does it.

### The compilation flag

Every debug-only site reads **`#if DEBUG || DIAGNOSTICS`**, never bare `#if DEBUG`. TestFlight archives in Release, where `DEBUG` is false; without the second condition a tester got a silent app and no log. `DIAGNOSTICS` is added to *Active Compilation Conditions* on the configuration used for tester builds — in Xcode, not the repo. **Without the flag the condition is what it always was — a pure no-op.**

**Do NOT instead define `DEBUG` in Release.** It changes assertion and optimisation behaviour across every dependency, so the tester's build stops being the build you tested.

At public release the reduction is automatic: leave the flag off and everything behind it vanishes. The real release question is not how much data but **what survives for a reader who cannot send a log**. Codex's answer: one on-page footer diagnostic, deliberately behind no flag at all, quiet by construction (on a healthy page nothing in it runs) — because a stranger's screenshot is the only diagnostic channel there is. And one instrument — a JavaScript round-trip that captures book text — must never ship publicly, whatever else does.

### The log is a FILE, in a folder the assistant reads

Console output is for Xcode. **The log that matters is a file** — one per launch — written to a folder in the app's iCloud container that the assistant reads directly from the Mac. On Codex: `~/Library/Mobile Documents/iCloud~<bundle-id>/Documents/Diagnostics`. After a test report, the assistant reads each device's latest log — stamp first, then the lines for each test. The tester does nothing.

Two things learned once the folder held more than one device's files:

- **Device tag in every filename.** Files were `codex-<date>-<time>.log`, and two iPads, a phone, and soon a dozen friends' devices all write into the same folder. The only way to tell them apart was to keep the other device out of the app. Now: `codex-<device>-<date>-<time>.log`, the same for panic screenshots and metrics files. **The folder listing is the report, so the name must carry it.** Slugify the device name; fall back to a stable per-install id when it is empty; print both on the launch line.
- **A small set of always-on lines reach the file even with the verbose switch off:** the build stamp, genuine errors, the hitch watchdog, the stall trap, and one wrong-colour capture. So every tester's device writes a small log whether or not they turn diagnostics on. Ruled *"fine for TestFlight"*; not yet ruled for a public release.

### Conventions inside the log

- **The stamp line first.** `[<name>-build] stamp: <label>` at launch, before anything else. The assistant reads it before interpreting a single other line.
- **A `[tag]` prefix per subsystem** — `[pos]`, `[save]`, `[sync]`, `[beacon]`, `[curl-hitch]`, `[battery]` — so a grep isolates one concern from a long session.
- **Log decisions, and say what the decision was made from.** `[pos] restore lands by element` / `by fraction`; `[save] … changes: place, no element`. A line that says *what* happened without *why* cannot be read against its neighbours.
- **Log the absence.** `[sync] NO EXPORT after 45 s` is the line that named a whole class of silent failures. A missing event needs a watchdog to write the line; nothing else will.
- **Summary lines at boundaries** — a reconcile summary at the end of a shelf scan, a save tally per save — so a 2,000-line log can be read from its milestones.
- **A dedicated always-on stall trap** that names the queue: Codex's one-second stall had a strong signature (1011, 1014, 1015, 1021 ms) that pointed at the web process for a week, until the trap showed `src0` — the main queue, our side — and the cause was a Metal drawable pool draining under a cold renderer. A strong signature still pointed the wrong way until the *phase* was measured.

### Hide failures on the visible path; log them silently

The user-visible path never shows a repairable failure and never spins forever:

- **Every wait gets a timeout and a fallback, at write time.** The owner: *"everything should have a timeout and a fall back."* An unbounded wait turns any rare failure — a corrupt file, a stuck server, a lagging cloud read — into a frozen screen with no information, worse than the failure itself (Codex: a 253-second infinite spinner, a stuck "Opening book…"). When writing any `await`/poll the UI sits behind, pair it with (1) a deadline and (2) a fallback the user can see or act on — an error, a degraded-but-honest result, a retry. A bare `await` on library code is the bug. In review, hunt for awaits with no timeout the same way as for force-unwraps.
- **Never trust a single signal with the user's screen.** Any gate that can hold the screen has a failsafe.
- **What reaches the user is labelled honestly, never blank and never stale.** An honest blank is actionable; a stale value is an undetectable lie.

### Long-run instruments

Some questions cannot be answered in a test round and need the device to run for hours with nobody watching:

- **A battery meter** writing `[battery] 87% unplugged — N min on the meter` every minute — because the OS reports battery in 5% steps and three 30-minute runs resolved nothing. With the line, ANY window is measurable after the fact. The protocol that replaced guessing: two overnight A/B runs, same build, same brightness, one variable changed.
- **A main-thread hitch watchdog** that logs any block over a threshold and says whether any instrumented code ran inside it (*"block is outside our code"* is itself a finding).
- **A main-thread stack sampler** — a watchdog thread that suspends the stuck main thread, walks its frames, resumes, and writes a `<device>-mainthread-<launch>.txt` beside the log. The signal-handler first cut deadlocked the phone; the watchdog-thread version does not. Its output ended a week of speculation about a slow phone in one file: every multi-second block was the dynamic loader paging in a system library on an OS beta.

A guess these replaced, untagged: "screen ~85–90%, machinery ~10–15%." Put the measured shares in the handoff and retire the guess.

**Endurance instruments — for a process that must run for months *(Revised 2026-09-04, Icarus)*:**

- **A symptom that worsens with uptime is a leak or a storm; measure its rate.** Icarus's app became unusable after ~24 hours of a run — dropped clicks, minutes of alarm delay, one core pegged — because a 0.1 s pad-rotation timer republished observed state ten times a second for the whole gap between measurements. The clue was that it *worsened*.
- **A watchdog threshold is proportionate to the cadence it watches.** Icarus's stall threshold was justified as "2 × the default 10-minute interval" and never revisited when the interval became 60 s; a hung loop burned twenty cycles before detection. Derive the threshold from the configured interval, not from a constant.
- **Measure the real cycle cost from the run's own log** and put it on the setup screen before the next run — a guard that sums configured waits passes a configuration that does not fit (see `02`, "Guards must measure the real cost").
- **Watch the memory-pressure kills on a small machine.** An 8 GB host logged a jetsam event during the first real run; the OS's diagnostic reports are where that shows up, not the app's log.

### Privacy, ruled explicitly

A tester's log carries titles and short prose excerpts, synced to their own iCloud. On Codex the owner ruled it fine for a named group of close friends, and tells them. If the group widens beyond people who were asked, the text-capturing instrument is gated separately. **Record the ruling and its scope; do not let a tester group grow past it silently.**

### What Icarus adds for an unattended instrument *(Revised 2026-09-04, Icarus)*

- **A companion log per run, beside the data.** Every line goes to the unified log *and* to `<run>/<run>.log` in the run's own folder, so the log travels with the data when the folder is archived or synced — which is how the assistant reads it from a synced copy without touching the lab machine. Lines before a run starts, or after it ends, go to the unified log only; they have no run to bind to.
- **A liveness heartbeat, as a FILE the customer can open.** Icarus writes *"heartbeat — status: …"* every five minutes. The first version used the unified log, which is the modern choice and was wrong for the audience: Console.app's device view is a live streamer that never shows history, so a technician opening it sees an empty window; reading history needs `log show` in Terminal, and *"the lab won't run the terminal."* Console does browse one thing — plain files under `~/Library/Logs`, in its Log Reports section — so the heartbeat goes there, with a plain-English header, its first line written immediately so the file exists to be found, self-trimmed past 5 MB. The unified-log line is still emitted for anyone who *will* run `log show`, because that puts the app on one timeline with the OS's own power and sleep events — exactly what was missing after the power loss.
- **Read the operating system's own reports.** macOS files resource-usage reports in `/Library/Logs/DiagnosticReports` (`.diag`). One of them caught a real Icarus bug nobody had noticed: 138 KB/s of sustained disk writes against a 99 KB/s daily limit — roughly a terabyte over 90 days against under half a gigabyte of actual data, which is write amplification from a database rewriting instead of appending. Check that folder after the first day of any long run, and after any incident. (Diagnosing the host also needs Terminal granted Full Disk Access ahead of time; without it `du` silently skips protected folders and under-reports by tens of gigabytes.)
- **Simulate the hardware you cannot exercise, at the sensor level.** A Debug menu item that fakes the *reading* (UPS on battery, power restored) runs the whole real chain downstream — pause, file comments, messages, resume gating — and marks every artefact `SIMULATED`. This is how a feature that depends on hardware the bench lacks gets rehearsed at all.
- **Record the flap, not only the absence.** A sensor counted as absent only at the instant of a read shows a loosening connector over 90 days as scattered single-cycle marks, indistinguishable from one bad moment. Icarus added a per-row "samples obtained of samples expected" column — the cheapest record of a partial dropout, and the kind of column that makes a file self-diagnosing.

---

## The Findings Report — written for the customer, from the instrument's own files *(Revised 2026-09-04, Icarus)*

When a real run exposes a defect, the person who needs to hear about it is the customer whose data it touched, and they will decide whether to trust the instrument on the strength of how it is told. Icarus's report on its first five-day run (`Docs/Reports/BurnIn5Days_Timing_Findings_2026-07-29.txt`, 469 lines of plain text) is the worked example; `TEMPLATES/FINDINGS_REPORT.md` is its shape. The order is the point:

1. **Summary — lead with whether the data is good.** *"Your data is good. Nothing was lost, nothing is corrupted."* Then the one number that is wrong, what it should have been, and the one operational consequence.
2. **What the run contains** — the settings and counts, so the reader can check they are looking at the same run.
3. **The problem**, in a table the reader can re-add.
4. **Why**, in physical terms — *"the reporting interval is not a container that the work is squeezed into"* — with measured figures, never estimates unless labelled.
5. **What this means for your data**, numbered, each with its size ("1.45% too early, increasingly so toward the end").
6. **How to correct the data you already have, by hand** — a spreadsheet formula, and the trap it must avoid (a leading zero Excel drops). The customer should not need a new build to recover their analysis.
7. **What is *not* a bug**, so nobody "fixes" it, and any secondary finding.
8. **What happens next**, in priority order, with the caveat stated plainly ("that is an estimate from the log, not a measurement").
9. **Recommended settings for the next run** — and where a setting is a *measurement* decision rather than a timing one, say so and hand it to the customer.
10. **Appendix — how these numbers were obtained.** Which log lines, how many, which files. *"Re-derivable; don't take it on faith."*

The handoff for the same day is a different document with a different reader — it holds the code locations, the partial-fix history and the traps for the next session. Send the report; do not send the handoff.

---

## Cross-References

- `02_DEVELOPMENT_PHILOSOPHY.md` — "Every Build Is Identifiable" (the automated stamp this file's protocol depends on; Codex's hand-maintained stamp went stale twice), "Never Lie in a Comment" (the guess-promoted-to-fact failure above is its diagnostics form).
- `08_WORKING_WITH_THE_OWNER.md` — the pacing, brevity and "read the code, don't ask" rules the test round runs on.
- `TEMPLATES/RELEASE_CHECKLIST.md` — where the stamp, the flag and the log folder meet a TestFlight upload.

---

*File status: first written 2026-09-04 from the Codex iOS project's August 2026 test rounds. Revised 2026-09-04 from the Icarus macOS project's first real runs (Tier 0, the shipped-unproven list, the bench-is-not-the-rig rule, measure-before-blaming, the unattended-instrument diagnostics, endurance instruments, the findings report).*
*Last updated: 2026-09-04.*
