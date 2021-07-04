tell application "Contacts"
	set thePeople to every person
	repeat with aPerson in thePeople
		set birthDate to birth date of aPerson
		log (get aPerson)
		if birthDate is not missing value then
			set prompt to "Remove birth date for " & quoted form of (get aPerson's name) & "?"
			set answer to button returned of (display dialog prompt buttons {"Remove", "Cancel", "Keep"} default button "Keep" cancel button "Cancel" with icon caution with title "Birthday Scrubber")
			if answer is "Remove" then
				set aPerson's birth date to missing value
				save aPerson
			end if
		end if
	end repeat
end tell