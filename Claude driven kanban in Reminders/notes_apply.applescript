-- Codex Kanban -- NOTES REWRITE, APPLY. This one WRITES.
--
-- Sets every card's NOTES to "K-0NN <dot> plain-English explanation. <pointer>".
-- Titles, sections, flags, priority and completion are NOT touched.
--
-- Why: the notes named Swift classes, which told the director nothing he could
-- picture, and no card had a stable handle to refer to in conversation. The id
-- goes FIRST so it survives Reminders truncating the note on the card face.
--
-- Pure ASCII on purpose; the replacement text comes from a UTF-8 data file via
-- `do shell script`, which decodes it correctly. Note that `do shell script`
-- returns CARRIAGE RETURNS, not linefeeds -- splitting on linefeed alone reads
-- the whole file as one line and silently yields zero rows. Hence both.
--
-- Idempotent: existing bodies are read in one go and a card is written only if
-- its text actually differs, so a second run is nearly free and cannot corrupt.

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

if rowCount is not 91 then
	return "ABORT: data file gave " & rowCount & " rows, expected 91. Nothing was changed."
end if

tell application "Reminders"
	if not (exists list "Codex Kanban") then
		return "ERROR: no list named 'Codex Kanban' found."
	end if
	tell list "Codex Kanban"
		set cardNames to name of every reminder
		set cardBodies to body of every reminder
	end tell
end tell
set cardCount to count of cardNames

-- resolve every card to its row BEFORE writing anything; refuse on any miss
set planIndex to {}
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
		return "ABORT: no data row for card -- " & nm & ". Nothing was changed."
	end if
	set end of planIndex to foundAt
end repeat

set didWrite to 0
set didSkip to 0
tell application "Reminders"
	tell list "Codex Kanban"
		repeat with c from 1 to cardCount
			set wanted to item (item c of planIndex) of theBodies
			set current to item c of cardBodies
			if current is missing value then set current to ""
			if current is not wanted then
				set body of reminder c to wanted
				set didWrite to didWrite + 1
			else
				set didSkip to didSkip + 1
			end if
		end repeat
	end tell
end tell

set rpt to "APPLY -- notes rewritten." & linefeed
set rpt to rpt & "cards        : " & cardCount & linefeed
set rpt to rpt & "notes written: " & didWrite & linefeed
set rpt to rpt & "unchanged    : " & didSkip & linefeed
set rpt to rpt & linefeed & "Titles, sections, flags and completion were not touched."
return rpt
