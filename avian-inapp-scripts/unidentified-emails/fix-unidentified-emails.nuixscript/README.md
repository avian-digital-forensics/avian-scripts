# Fix unidentified emails
Tries to find the communication fields of selected emails unidentified by Nuix.
Looks in the text for fields like To, From, and Date, and if it can't find them the script searches through the item's properties.

## Technical details
It is assumed that each field ("date", "subject") is on its on line, and that nothing else is on that line.
It is assumed that only the lines containing fields start with field aliases.
If two lines start with the same alias for an identifier, only the first will be read.