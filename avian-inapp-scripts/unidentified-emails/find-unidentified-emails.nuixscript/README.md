# Find unidentified emails
Tries to find items that should be emails but aren't identified as such by Nuix.
Gives each such item the specified tag.

If items are selected, the script runs only on those.
Otherwise, a search is run to find likely candidates and the script is run on the resulting items.

## How it works
The script looks for items whose content starts with something that looks like a From, To and Subject.