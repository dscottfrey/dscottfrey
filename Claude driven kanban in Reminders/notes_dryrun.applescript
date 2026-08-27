-- Codex Kanban -- NOTES REWRITE, DRY RUN. Reads only. Modifies nothing.
--
-- Rewrites every card's NOTES to: "K-0NN <dot> plain-English explanation. <pointer>"
-- so that (a) each card has a permanent short id you can refer to in conversation,
-- and (b) the note says what a person holding the iPad would notice, instead of
-- naming Swift classes. Titles, sections, flags and completion are NOT touched.
--
-- The replacement text lives in a separate UTF-8 data file rather than inline,
-- because this script must stay pure ASCII: the original batch scripts are
-- MacRoman and mixing the two encodings is what mangles every separator.
-- `do shell script` hands back UTF-8 correctly, so the data keeps its accents.
--
-- Matching is on the card's EXACT full title. This run reports failures in BOTH
-- directions -- a data row that matched no card, and a card that no data row
-- claimed -- because a silent half-match is the failure worth catching.

-- ABSOLUTE on purpose: `do shell script` always starts in /, so a relative
-- path silently finds nothing. Change this line if the repo ever moves.
set dataPath to "/Users/scott/Documents/Code/Codex Reader/scripts/kanban/notes.tsv"

set raw to do shell script "cat " & quoted form of dataPath
set AppleScript's text item delimiters to {return, linefeed}
set dataLines to text items of raw
set AppleScript's text item delimiters to tab

set theKeys to {}
set theBodies to {}
repeat with ln in dataLines
	set parts to text items of (ln as text)
	if (count of parts) is 2 then
		set end of theKeys to item 1 of parts
		set end of theBodies to item 2 of parts
	end if
end repeat
set AppleScript's text item delimiters to ""
set rowCount to count of theKeys

tell application "Reminders"
	if not (exists list "Codex Kanban") then
		return "ERROR: no list named 'Codex Kanban' found."
	end if
	tell list "Codex Kanban"
		set cardNames to name of every reminder
	end tell
end tell
set cardCount to count of cardNames

set matched to 0
set unclaimedCards to {}
set usedRow to {}
repeat with i from 1 to rowCount
	set end of usedRow to false
end repeat

repeat with c from 1 to cardCount
	set nm to item c of cardNames
	set foundAt to 0
	repeat with i from 1 to rowCount
		if (item i of theKeys) is nm then
			set foundAt to i
			exit repeat
		end if
	end repeat
	if foundAt is 0 then
		set end of unclaimedCards to nm
	else
		set matched to matched + 1
		set item foundAt of usedRow to true
	end if
end repeat

set orphanRows to {}
repeat with i from 1 to rowCount
	if not (item i of usedRow) then set end of orphanRows to (item i of theKeys)
end repeat

set rpt to "DRY RUN -- nothing was changed." & linefeed
set rpt to rpt & "cards in list  : " & cardCount & linefeed
set rpt to rpt & "rows in data   : " & rowCount & linefeed
set rpt to rpt & "matched        : " & matched & linefeed
set rpt to rpt & "cards with no data row : " & (count of unclaimedCards) & linefeed
repeat with u in unclaimedCards
	set rpt to rpt & "   CARD NOT IN DATA: " & (u as text) & linefeed
end repeat
set rpt to rpt & "data rows matching no card : " & (count of orphanRows) & linefeed
repeat with o in orphanRows
	set rpt to rpt & "   DATA NOT ON BOARD: " & (o as text) & linefeed
end repeat

if matched is cardCount and (count of orphanRows) is 0 then
	set rpt to rpt & linefeed & "ALL 91 MATCHED BOTH WAYS. Safe to apply." & linefeed
	set rpt to rpt & "Example of the new note text:" & linefeed
	set rpt to rpt & "   " & (item 1 of theBodies) & linefeed
else
	set rpt to rpt & linefeed & "MISMATCH -- do not apply until this is resolved." & linefeed
end if
return rpt
