-- Codex Kanban -- PROBE. Read-only. Reports what AppleScript can actually see,
-- and NAMES any card that has gone missing.
--
-- THE SUBTASK TRAP, measured 2026-08-27. Dropping one card onto another in
-- Reminders makes it a SUBTASK, and a subtask is invisible to AppleScript
-- entirely -- the count went 92 -> 91 and every property of that card became
-- unreadable. So this script cannot detect the indent directly; it can only
-- detect the absence. It therefore compares the board against the id register
-- and tells you which id vanished.
--
-- THE FIX IS NOT UNDO. In Reminders, select the card and use
-- **Outdent Reminder**. It then reappears to every script.
--
-- Run this after any session of heavy rearranging, and any time a bulk script
-- aborts saying a known card is not on the board.

-- ABSOLUTE on purpose: `do shell script` always starts in /.
set dataPath to "/Users/scott/Documents/Code/Codex Reader/scripts/kanban/retier.tsv"

set raw to do shell script "cat " & quoted form of dataPath
set AppleScript's text item delimiters to {return, linefeed}
set dataLines to text items of raw
set AppleScript's text item delimiters to tab
set knownIDs to {}
set knownNames to {}
repeat with ln in dataLines
	set parts to text items of (ln as text)
	if (count of parts) is 3 then
		if (item 1 of parts) is not "NEW" then
			set end of knownIDs to item 1 of parts
			set end of knownNames to item 3 of parts
		end if
	end if
end repeat
set AppleScript's text item delimiters to ""
set knownCount to count of knownIDs

tell application "Reminders"
	if not (exists list "Codex Kanban") then return "ERROR: no list 'Codex Kanban'."
	tell list "Codex Kanban"
		set theNames to name of every reminder
		set theBodies to body of every reminder
	end tell
end tell

set n to count of theNames
set seen to {}
set noID to {}
repeat with i from 1 to n
	set b to item i of theBodies
	if b is missing value then set b to ""
	set kid to ""
	if (length of b) > 5 then
		if text 1 thru 2 of b is "K-" then set kid to text 1 thru 5 of b
	end if
	if kid is "" then
		set end of noID to (item i of theNames)
	else
		set end of seen to kid
	end if
end repeat

set missing to {}
repeat with i from 1 to knownCount
	set k to item i of knownIDs
	set found to false
	repeat with s in seen
		if (s as text) is k then
			set found to true
			exit repeat
		end if
	end repeat
	if not found then set end of missing to (k & "  " & (item i of knownNames))
end repeat

-- Reminders truncates a long note on the card face WITHOUT an ellipsis, so an
-- overflowing note looks like a complete sentence that simply stops. Measured
-- 2026-08-27 against a full-board screenshot: 249 characters displayed in full,
-- 263 was cut. The safe ceiling is 250. Anything longer belongs on the glossary
-- page, not on a card.
set tooLong to {}
repeat with i from 1 to n
	set b to item i of theBodies
	if b is not missing value then
		if (length of b) > 250 then
			set end of tooLong to ((length of b) as text) & "  " & (item i of theNames)
		end if
	end if
end repeat

set rpt to "PROBE -- nothing was changed." & linefeed
set rpt to rpt & "cards AppleScript can see : " & n & linefeed
set rpt to rpt & "cards with a K- id        : " & (count of seen) & linefeed
set rpt to rpt & "cards with NO id          : " & (count of noID) & linefeed
repeat with x in noID
	set rpt to rpt & "   NEW OR UNTRACKED: " & (x as text) & linefeed
end repeat
set rpt to rpt & "notes over 250 chars      : " & (count of tooLong) & linefeed
repeat with t in tooLong
	set rpt to rpt & "   TRUNCATED ON CARD: " & (t as text) & linefeed
end repeat
set rpt to rpt & "known cards MISSING       : " & (count of missing) & linefeed
repeat with m in missing
	set rpt to rpt & "   " & (text 1 thru 90 of ((m as text) & "                                                                                          ")) & linefeed
end repeat
if (count of missing) > 0 then
	set rpt to rpt & linefeed & "A missing card is almost certainly nested as a subtask." & linefeed
	set rpt to rpt & "Select it in Reminders and use OUTDENT REMINDER. Undo will not do it." & linefeed
end if
return rpt
