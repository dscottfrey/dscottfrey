-- Codex Kanban -- create the GLOSSARY card (K-000). Run once; safe to re-run.
--
-- K-000 is reserved for this card and is not work. It is a POINTER, not the
-- glossary itself: Reminders truncates a note past ~250 characters with no
-- ellipsis, so a real glossary in a note is unreadable at any length it will
-- show. The full version is a web page; this card carries the three column
-- meanings worth having unprompted, and the link. The bulk scripts recognise
-- K-000 and deliberately skip it: its body contains newlines, and the TSV they
-- read cannot carry those.
--
-- Idempotent: if a card whose note starts with K-000 already exists, its text is
-- refreshed rather than a second card created. That is also how the glossary is
-- edited -- change this file and run it again.
--
-- Pure ASCII source; every accented character is built with `character id`, and
-- the long concatenations are deliberate. The AppleScript line-continuation
-- character is itself non-ASCII, so wrapping them would defeat the point.

set cardTitle to "GLOSSARY " & (character id 183) & " How to read a card"

set cardBody to "K-000 " & (character id 183) & " The glossary, not work. Columns say what kind of work is left. WIRE = built but unreachable. DRIFT = needs a ruling, not building. Defer = above v1.0. Full glossary: https://claude.ai/code/artifact/d0eebb66-71cd-421e-a7f0-fbb25bc33536"

tell application "Reminders"
	if not (exists list "Codex Kanban") then return "ERROR: no list 'Codex Kanban'."
	tell list "Codex Kanban"
		set theNames to name of every reminder
		set theBodies to body of every reminder
		set found to 0
		repeat with i from 1 to (count of theNames)
			set b to item i of theBodies
			if b is not missing value and (length of b) > 5 then
				if text 1 thru 5 of b is "K-000" then set found to i
			end if
		end repeat
		if found is 0 then
			make new reminder with properties {name:cardTitle, body:cardBody}
			set msg to "CREATED the glossary card."
		else
			set name of reminder found to cardTitle
			set body of reminder found to cardBody
			set msg to "REFRESHED the existing glossary card."
		end if
		set n to count of reminders
	end tell
end tell
return msg & " Cards on board now: " & n
