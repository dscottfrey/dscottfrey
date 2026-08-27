-- Codex Kanban -- APPLY. This one WRITES.
--
-- Companion to codex_kanban_dryrun.applescript. Same match list, same logic;
-- the only difference is that it sets `body` and `flagged` instead of reporting.
--
-- WHAT IT DOES, exactly:
--   * 11 cards: prepends "WIRE -- " or "DRIFT -- " (real em dash) to the NOTES.
--     Existing note text is preserved, never replaced.
--   * 2 cards: sets flagged = true.
--   * Nothing else is touched. No card is created, renamed, moved, completed,
--     or deleted. Titles are never modified.
--
-- WHY: a card's kind (wire/drift/blocker) exists nowhere but its section, and
-- AppleScript cannot see sections. Dragging a card to another column erases
-- that knowledge. Stamping it into the notes makes it survive any rearrangement.
--
-- IDEMPOTENT: a card whose notes already start with the prefix is skipped, so
-- running this twice cannot double-stamp. That is also the undo test -- if the
-- report says "already stamped" for everything, the work is done.
--
-- Source is pure ASCII on purpose (the original batch scripts are MacRoman;
-- mixing encodings is what mangles every separator). Non-ASCII output
-- characters are built with `character id`, which no encoding can corrupt.

set emDash to character id 8212

set wireKeys to {"Duplicate detection on the folder path", "Sidecars are never written", "Annotation export has no access point", "Recently Active Books stack unused", "OPDS is an island"}

set driftKeys to {"describes a Core Image compositor", "Two ingestion paths, one live", "Collections vs folder-as-shelf", "Ruling 3 not enforced", "Undirected subsystems", "BookContentBlocker has no directive"}

set blockerKeys to {"Launch-screen entry in Info.plist", "Diagnostics off by default"}

set stampPlan to {{wireKeys, "WIRE"}, {driftKeys, "DRIFT"}}
set didStamp to 0
set didSkip to 0
set didFlag to 0
set problems to {}
set rpt to "APPLY -- writing to the Codex Kanban list." & linefeed & linefeed

tell application "Reminders"
	if not (exists list "Codex Kanban") then
		return "ERROR: no list named 'Codex Kanban' found. Nothing was changed."
	end if
	tell list "Codex Kanban"
		set theNames to name of every reminder
		set cardCount to count of theNames
		
		repeat with grp in stampPlan
			set theKeys to item 1 of grp
			set theWord to item 2 of grp
			set thePrefix to theWord & " " & emDash & " "
			repeat with k in theKeys
				set kk to k as text
				set hits to 0
				repeat with i from 1 to cardCount
					set nm to item i of theNames
					if nm contains kk then
						set hits to hits + 1
						set r to reminder i
						set bd to body of r
						if bd is missing value then set bd to ""
						if bd starts with thePrefix then
							set rpt to rpt & "SKIP    " & nm & linefeed
							set didSkip to didSkip + 1
						else
							set body of r to (thePrefix & bd)
							set rpt to rpt & "STAMPED " & theWord & "  " & nm & linefeed
							set didStamp to didStamp + 1
						end if
					end if
				end repeat
				if hits is not 1 then
					set end of problems to (theWord & " matched " & hits & " cards for: " & kk)
				end if
			end repeat
		end repeat
		
		repeat with k in blockerKeys
			set kk to k as text
			set hits to 0
			repeat with i from 1 to cardCount
				set nm to item i of theNames
				if nm contains kk then
					set hits to hits + 1
					set r to reminder i
					if flagged of r then
						set rpt to rpt & "SKIP    already flagged  " & nm & linefeed
					else
						set flagged of r to true
						set rpt to rpt & "FLAGGED " & nm & linefeed
						set didFlag to didFlag + 1
					end if
				end if
			end repeat
			if hits is not 1 then
				set end of problems to ("BLOCKER matched " & hits & " cards for: " & kk)
			end if
		end repeat
	end tell
end tell

set rpt to rpt & linefeed & "---- SUMMARY ----" & linefeed
set rpt to rpt & "notes stamped  : " & didStamp & linefeed
set rpt to rpt & "skipped (done) : " & didSkip & linefeed
set rpt to rpt & "flags set      : " & didFlag & linefeed
set rpt to rpt & "problems       : " & (count of problems) & linefeed
repeat with p in problems
	set rpt to rpt & "   - " & (p as text) & linefeed
end repeat
set rpt to rpt & linefeed & "Titles, sections, and completion states were not touched."
return rpt
