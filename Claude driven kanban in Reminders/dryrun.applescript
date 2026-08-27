-- Codex Kanban -- DRY RUN. Reads only. Modifies nothing, creates nothing.
--
-- Purpose: the board's only record of a card's KIND (wire / drift / blocker)
-- is which section it sits in, and AppleScript cannot see sections. So the
-- moment a card is dragged to another column, that knowledge is gone.
-- This stamps the kind into the NOTES instead, where it is visible on the
-- card, survives any move, and is scriptable.
--
-- Source is deliberately pure ASCII: the original batch scripts are MacRoman,
-- and mixing encodings is what turns every separator into garbage. Any
-- non-ASCII character below is built with `character id`, which is encoding-proof.
--
-- Cards are matched on a distinctive ASCII fragment of the title, NOT the whole
-- title, so the middle-dot separators and section marks cannot break the match.

set emDash to character id 8212

set wireKeys to {"Duplicate detection on the folder path", "Sidecars are never written", "Annotation export has no access point", "Recently Active Books stack unused", "OPDS is an island"}

set driftKeys to {"describes a Core Image compositor", "Two ingestion paths, one live", "Collections vs folder-as-shelf", "Ruling 3 not enforced", "Undirected subsystems", "BookContentBlocker has no directive"}

set blockerKeys to {"Launch-screen entry in Info.plist", "Diagnostics off by default"}

tell application "Reminders"
	if not (exists list "Codex Kanban") then
		return "ERROR: no list named 'Codex Kanban' found."
	end if
	tell list "Codex Kanban"
		set theNames to name of every reminder
		set theBodies to body of every reminder
		set theFlags to flagged of every reminder
	end tell
end tell

set cardCount to count of theNames
set rpt to "DRY RUN -- nothing was changed." & linefeed
set rpt to rpt & "Cards in list: " & cardCount & linefeed & linefeed

set stampPlan to {{wireKeys, "WIRE"}, {driftKeys, "DRIFT"}}
set willChange to 0
set alreadyDone to 0
set notFound to {}

repeat with grp in stampPlan
	set theKeys to item 1 of grp
	set theWord to item 2 of grp
	set thePrefix to theWord & " " & emDash & " "
	set rpt to rpt & "=== " & theWord & " -- stamp into notes ===" & linefeed
	repeat with k in theKeys
		set kk to k as text
		set hits to 0
		repeat with i from 1 to cardCount
			set nm to item i of theNames
			if nm contains kk then
				set hits to hits + 1
				set bd to item i of theBodies
				if bd is missing value then set bd to ""
				set rpt to rpt & "  CARD : " & nm & linefeed
				if bd starts with thePrefix then
					set rpt to rpt & "  SKIP : already stamped" & linefeed & linefeed
					set alreadyDone to alreadyDone + 1
				else
					set rpt to rpt & "  from : " & bd & linefeed
					set rpt to rpt & "  to   : " & thePrefix & bd & linefeed & linefeed
					set willChange to willChange + 1
				end if
			end if
		end repeat
		if hits is 0 then
			set end of notFound to (theWord & ": " & kk)
			set rpt to rpt & "  ** NO MATCH: " & kk & linefeed & linefeed
		else if hits > 1 then
			set rpt to rpt & "  ** WARNING: " & hits & " cards matched " & kk & linefeed & linefeed
		end if
	end repeat
end repeat

set rpt to rpt & "=== BLOCKER -- set the flag ===" & linefeed
set willFlag to 0
repeat with k in blockerKeys
	set kk to k as text
	set hits to 0
	repeat with i from 1 to cardCount
		set nm to item i of theNames
		if nm contains kk then
			set hits to hits + 1
			set rpt to rpt & "  CARD : " & nm & linefeed
			if item i of theFlags then
				set rpt to rpt & "  SKIP : already flagged" & linefeed & linefeed
			else
				set rpt to rpt & "  to   : flagged = true" & linefeed & linefeed
				set willFlag to willFlag + 1
			end if
		end if
	end repeat
	if hits is 0 then
		set end of notFound to ("BLOCKER: " & kk)
		set rpt to rpt & "  ** NO MATCH: " & kk & linefeed & linefeed
	end if
end repeat

set rpt to rpt & "---- SUMMARY ----" & linefeed
set rpt to rpt & "notes to stamp : " & willChange & linefeed
set rpt to rpt & "already stamped: " & alreadyDone & linefeed
set rpt to rpt & "flags to set   : " & willFlag & linefeed
set rpt to rpt & "unmatched keys : " & (count of notFound) & linefeed
if (count of notFound) > 0 then
	repeat with u in notFound
		set rpt to rpt & "   - " & (u as text) & linefeed
	end repeat
end if
set rpt to rpt & linefeed & "Nothing above was applied."
return rpt
