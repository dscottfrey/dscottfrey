-- Codex Kanban -- SUBTASK EXPERIMENT. Read-only.
--
-- Question: when a card is dropped onto another and becomes a subtask, the
-- list's `every reminder` count falls by one. Where did it go?
--
--   Hypothesis A -- subtasks are simply excluded from `every reminder`, and
--                   are reachable as `reminders of reminder N`. Nothing is
--                   lost; the scripts just need a second look.
--   Hypothesis B -- subtasks are unreachable from AppleScript at all. An
--                   accidental drop genuinely hides a card from every script.
--
-- HOW TO RUN IT: nest one card under another first, then run this. It reports
-- the count, and for every card tries to ask for child reminders, reporting
-- what happens. Outdent afterwards.

tell application "Reminders"
	if not (exists list "Codex Kanban") then return "ERROR: no list 'Codex Kanban'."
	tell list "Codex Kanban"
		set theNames to name of every reminder
		set n to count of theNames
	end tell
end tell

set rpt to "SUBTASK PROBE -- nothing was changed." & linefeed
set rpt to rpt & "top-level cards visible : " & n & linefeed & linefeed

set childTotal to 0
set errText to ""
repeat with i from 1 to n
	try
		tell application "Reminders"
			tell list "Codex Kanban"
				set kids to count of (reminders of reminder i)
			end tell
		end tell
		if kids > 0 then
			set rpt to rpt & "CHILDREN: " & kids & " under -- " & (item i of theNames) & linefeed
			set childTotal to childTotal + kids
		end if
	on error e
		if errText is "" then set errText to e
	end try
end repeat

if errText is not "" then
	set rpt to rpt & "HYPOTHESIS B -- `reminders of reminder` is not supported." & linefeed
	set rpt to rpt & "AppleScript error was:" & linefeed & "   " & errText & linefeed
	set rpt to rpt & "A nested card is unreachable. Outdent is the only recovery." & linefeed
else
	set rpt to rpt & linefeed & "child cards found : " & childTotal & linefeed
	if childTotal > 0 then
		set rpt to rpt & "HYPOTHESIS A -- subtasks ARE reachable, just not top level." & linefeed
	else
		set rpt to rpt & "No children found. Either nothing is nested right now," & linefeed
		set rpt to rpt & "or they are invisible (hypothesis B) without raising an error." & linefeed
	end if
end if
return rpt
