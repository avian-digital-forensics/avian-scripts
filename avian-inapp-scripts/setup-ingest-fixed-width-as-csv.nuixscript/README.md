# Setup Ingest Fixed Width as CSV
Performs the necessary setup for the WSS script 'Ingest Fixed Width as CSV'.
Selected items should have custom metadata fields "ColumnTypes", "ColumnHeaders", "LineFormat", and "MaxDateDiff".
* ColumnTypes - A comma seperated list of the types of each column (date/id/sum/discard).
  * date - Entries where these values are close enough and have the same id values will be combined.
  * id - Entries where these values are equal and the date values are close enough will be combined.
  * sum - When two entries are combined, these valued will be summed in the resulting entry.
  * discard - These values will be ignored and have no effect on the final CSV.
* ColumnHeaders - A comma separated list of the headers for each column.
* LineFormat - A comma separated string of the start positions (zero-indexed) for each column in the fixed width file with and additional index for the end of the line.
* MaxDateDiff - The maximum difference in seconds between two entries' date fields for them to be combined.
