tell application "Reminders"
	set expirationDate to (current date) - 30 * days
	set removeSet to every reminder whose completion date comes before expirationDate
	set removeSetRef to a reference to removeSet
	log "Found " & (count reminders) & " reminders"
	log "Deleting " & (count removeSetRef) & " reminders completed before " & (expirationDate as text)
	repeat while (count removeSetRef) > 0
		delete first item of removeSetRef
		set removeSetRef to rest of removeSetRef
	end repeat
end tell