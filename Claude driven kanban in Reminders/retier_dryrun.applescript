-- Codex Kanban -- RE-TIER + SIZE. Set DRY_RUN to false to write.
--
-- KEYED ON THE CARD ID, NOT THE TITLE. This matters: Scott re-tiers cards by
-- retyping the title in Reminders, so a title-keyed script breaks the moment he
-- touches the board -- which is backwards, because the board is his. The id in
-- the note never changes, so he can retype a title however he likes and this
-- still finds the card.
--
-- It also NEVER rewrites a title it was not explicitly told to change. An
-- earlier title-keyed version would have silently reverted a hand edit.
--
-- Data columns, tab separated: id <TAB> newTitle <TAB> newBody
--   * id "NEW"        -> create this card (it has no id on the board yet)
--   * newTitle empty  -> leave the title exactly as it is on the board
--
-- One pass, three jobs, because every Reminders write costs an iCloud sync and
-- 90-odd of them is minutes of beachball.
--
-- Pure ASCII source; accented text lives in the UTF-8 data file, read with
-- `do shell script`, which returns CARRIAGE RETURNS -- hence the two-delimiter
-- split. Splitting on linefeed alone silently yields zero rows.

set DRY_RUN to true

-- ABSOLUTE on purpose: `do shell script` always starts in /, so a relative path
-- silently finds nothing. Change this line if the repo ever moves.
set dataPath to "/Users/scott/Documents/Code/Codex Reader/scripts/kanban/retier.tsv"

set raw to do shell script "cat " & quoted form of dataPath
set AppleScript's text item delimiters to {return, linefeed}
set dataLines to text items of raw
set AppleScript's text item delimiters to tab
set rowIDs to {}
set newNames to {}
set newBodies to {}
repeat with ln in dataLines
	set parts to text items of (ln as text)
	if (count of parts) is 3 then
		set end of rowIDs to item 1 of parts
		set end of newNames to item 2 of parts
		set end of newBodies to item 3 of parts
	end if
end repeat
set AppleScript's text item delimiters to ""
set rowCount to count of rowIDs
if rowCount is 0 then return "ABORT: data file parsed to zero rows. Nothing changed."

tell application "Reminders"
	if not (exists list "Codex Kanban") then return "ERROR: no list 'Codex Kanban'."
	tell list "Codex Kanban"
		set cardNames to name of every reminder
		set cardBodies to body of every reminder
	end tell
end tell
set cardCount to count of cardNames

-- Every card's id is the first five characters of its note: "K-0NN".
set planRow to {}
set orphans to {}
repeat with c from 1 to cardCount
	set bd to item c of cardBodies
	if bd is missing value then set bd to ""
	set kid to ""
	if (length of bd) > 5 then set kid to text 1 thru 5 of bd
	set hit to 0
	if kid is not "" then
		repeat with i from 1 to rowCount
			if (item i of rowIDs) is kid then
				set hit to i
				exit repeat
			end if
		end repeat
	end if
	-- K-000 is the glossary card, not work. It is authored once by
	-- create_glossary_card.applescript and must never be rewritten from the
	-- data file: its body contains newlines, which a TSV cannot carry.
	if kid is "K-000" then set hit to -1
	if hit is 0 then set end of orphans to (item c of cardNames)
	set end of planRow to hit
end repeat

if (count of orphans) > 0 then
	set msg to "ABORT: " & (count of orphans) & " card(s) carry no known id. Nothing changed." & linefeed
	repeat with o in orphans
		set msg to msg & "   " & (o as text) & linefeed
	end repeat
	return msg
end if

-- Every data row must also find a card. A card nested as a SUBTASK becomes
-- invisible to AppleScript entirely -- measured 2026-08-27, a drop took the
-- count from 92 to 91 -- so without this check a hidden card is silently
-- skipped and its note quietly goes stale. Refuse instead.
set usedRow to {}
repeat with i from 1 to rowCount
	set end of usedRow to false
end repeat
repeat with c from 1 to cardCount
	set i to item c of planRow
	if i > 0 then set item i of usedRow to true
end repeat
set missingCards to {}
repeat with i from 1 to rowCount
	if not (item i of usedRow) and (item i of rowIDs) is not "NEW" then
		set end of missingCards to (item i of rowIDs)
	end if
end repeat
if (count of missingCards) > 0 then
	set msg to "ABORT: " & (count of missingCards) & " known card(s) are NOT on the board. Nothing changed." & linefeed
	set msg to msg & "A card dropped onto another becomes a subtask and vanishes from AppleScript." & linefeed
	set msg to msg & "Un-nest it, or run probe.applescript to see the count." & linefeed
	repeat with m in missingCards
		set msg to msg & "   " & (m as text) & linefeed
	end repeat
	return msg
end if

set renames to 0
set bodyWrites to 0
set rpt to ""
repeat with c from 1 to cardCount
	set i to item c of planRow
	if i is -1 then set i to 0
	set nm to item c of cardNames
	if i is 0 then
		set wantName to nm
		set wantBody to (item c of cardBodies)
	else
		set wantName to item i of newNames
		set wantBody to item i of newBodies
	end if
	set curBody to item c of cardBodies
	if curBody is missing value then set curBody to ""
	if wantName is not "" and nm is not wantName then
		set rpt to rpt & "RENAME  " & nm & linefeed & "    ->  " & wantName & linefeed
		set renames to renames + 1
		if not DRY_RUN then
			tell application "Reminders" to tell list "Codex Kanban" to set name of reminder c to wantName
		end if
	end if
	if curBody is not wantBody then
		set bodyWrites to bodyWrites + 1
		if not DRY_RUN then
			tell application "Reminders" to tell list "Codex Kanban" to set body of reminder c to wantBody
		end if
	end if
end repeat

set created to 0
repeat with i from 1 to rowCount
	if (item i of rowIDs) is "NEW" then
		set rpt to rpt & "CREATE  " & (item i of newNames) & linefeed
		set created to created + 1
		if not DRY_RUN then
			tell application "Reminders"
				tell list "Codex Kanban"
					make new reminder with properties {name:(item i of newNames), body:(item i of newBodies)}
				end tell
			end tell
		end if
	end if
end repeat

if DRY_RUN then
	set head to "DRY RUN -- nothing was changed." & linefeed
else
	set head to "APPLIED." & linefeed
end if
set rpt to head & rpt & linefeed & "---- SUMMARY ----" & linefeed
set rpt to rpt & "cards on board : " & cardCount & linefeed
set rpt to rpt & "renames        : " & renames & linefeed
set rpt to rpt & "notes rewritten: " & bodyWrites & linefeed
set rpt to rpt & "cards created  : " & created & linefeed
set rpt to rpt & linefeed & "Titles not listed for change were left exactly as they are."
return rpt
