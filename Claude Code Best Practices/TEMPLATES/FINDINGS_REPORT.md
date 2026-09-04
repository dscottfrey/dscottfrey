# [Project] — "[Run name]" [Topic] Findings

*Template added 2026-09-04, Icarus. Generalised from
`Docs/Reports/BurnIn5Days_Timing_Findings_2026-07-29.txt` — a 469-line plain-text
report written for a lab operator after the instrument's first real five-day run.
The reader is the customer whose data this touches, not a developer. Plain text or
plain Markdown; no code; every number re-derivable from the files named in the
appendix. See `07_TESTING_AND_DIAGNOSTICS.md` — "The Findings Report".*

Date: [YYYY-MM-DD]
Source: [the run's own log (N lines) + the data files read]
Run: [start → end, in the customer's local time]
Build: [marketing version (build stamp)]


SUMMARY
-------
[Lead with whether the data is good. On Icarus: "Your data is good. Nothing was
lost, nothing is corrupted, and all six bays recorded every cycle."]

[Then the ONE number that is wrong, shown against what it should have been:]

    [what the screen said]        [e.g. 4d 22h 21m]
    [what it actually was]        [e.g. 5d 00h 05m 34s]

[Then the one operational consequence, if there was one — the thing that did or
did not HAPPEN, as distinct from a number that was merely displayed wrong.]

[Then: the correct value is still recoverable from your files, and how (pointer to
CORRECTING THE DATA YOU ALREADY HAVE).]

[Any second, unrelated finding gets one paragraph here and its own section below.]

[Close: "Both will be corrected in the app. Details are at the end."]


WHAT THE RUN CONTAINS
---------------------
  [Setting]:            [value]
  [Setting]:            [value]
  [Cycles / rows / days / bays]: [counts, so the reader can confirm this is their run]

[One "aside" per oddity in the settings that is harmless but will puzzle them —
e.g. where an extra five minutes of duration came from.]


THE PROBLEM
-----------
[The mechanism in one sentence, then a table the reader can re-add:]

  [what the system obeyed]       [quantity]        [value]
  [what the screen showed]       [quantity]        [value]
                                                   ---------
  Difference                                       [value]


WHY [IT HAPPENED]
-----------------
[Physical explanation, in the customer's terms. Measured figures only; anything
estimated is labelled "estimate". A "configured vs actual" table if timing is
involved. Name what CANNOT be removed (real hardware time) versus what can.]


WHY [THE SAFEGUARD] DID NOT WARN YOU
------------------------------------
[If a guard existed and passed: say it exists, say what it measured, say why that
was the wrong thing. "The guard is real, but it was measuring the wrong thing."]


[THE CONSEQUENCE THAT MATTERED] — reported by [who]
---------------------------------------------------
[When something failed to happen (a reminder, an alert), its own section: confirm
the report, show the arithmetic that made it impossible, state the rule the
customer should apply "for as long as this build is in use".]


WHAT THIS MEANS FOR YOUR DATA
-----------------------------
[Numbered. Each: what is affected, by how much, whether it grows, and whether it
matters for the analysis they are doing. End with what is NOT affected.]


CORRECTING THE DATA YOU ALREADY HAVE
------------------------------------
[The hand fix — a spreadsheet formula, a column to use instead — and the trap it
must avoid (e.g. set the timestamp column to TEXT on import or the leading zero is
lost). "You do not need to re-run anything."]


DATA QUALITY
------------
[Faults raised, rows flagged, pauses, stalls, rollovers, agreement between files.
Name any deliberate test the customer ran and say the system responded as
intended — credit where due.]


[SECONDARY FINDING — one per section]
--------------------------------------
[What, where (rows / cells), why it matters, RECOMMENDED fix, UNTIL THAT SHIPS
what to do by hand.]


A NOTE ON [SOMETHING THAT LOOKS WRONG AND IS RIGHT]
----------------------------------------------------
[Recorded so nobody revisits it later and "fixes" it into being wrong. Say what it
looks like, why it is correct, "No change recommended here."]


WHAT HAPPENS NEXT
-----------------
[Numbered, in the order they matter, smallest-and-most-important first. Each in
one paragraph. Then ONE CAVEAT, STATED PLAINLY: what is an estimate, what a short
run would settle, and that it is recommended before the next long run.]


RECOMMENDED SETTINGS FOR THE NEXT LONG RUN
------------------------------------------
[The safe lever and why. Where an alternative is a MEASUREMENT decision rather than
a timing one, say so in capitals and hand it to the customer: "THIS IS A
MEASUREMENT DECISION, NOT A TIMING ONE, and it is the lab's call, not the
software's."]


APPENDIX — HOW THESE NUMBERS WERE OBTAINED
------------------------------------------
[Which log lines, how many of them; which files; which columns. Measured min /
mean / max where relevant. Anything checked as a possible cause and RULED OUT,
with the figures, so it is not re-tested. "No estimates except where explicitly
labelled." "Re-derivable; don't take it on faith."]

  END OF REPORT
