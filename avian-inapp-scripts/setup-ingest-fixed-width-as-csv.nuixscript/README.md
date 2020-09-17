# Setup Ingest Fixed Width as CSV
Performs the necessary setup for the WSS script 'Ingest Fixed Width as CSV'.
Selected items should have custom metadata fields "ColumnTypes", "ColumnHeaders", "LineFormat", and "MaxDateDiff".
The data type of the filed is written in square brackets after the name.
* ColumnTypes \[Text\] - A comma seperated list of the types of each column (date/id/sum/discard). Column types in bold must be included
  * **date** - Entries where these values are close enough and have the same id values will be combined.
  * id - Entries where these values are equal and the date values are close enough will be combined.
  * **from** - The From of the resulting communication. Is also handled as an id.
  * **to** - The To of the resulting communication. Is also handled as an id.
  * sum - When two entries are combined, these valued will be summed in the resulting entry.
  * discard - These values will be ignored and have no effect on the final CSV.
* ColumnHeaders \[Text\] - A comma separated list of the headers for each column. Only add a header for the columns not given type 'discard'.
* LineFormat \[Text\] - A comma separated string of the start positions (zero-indexed) for each column in the fixed width file with. Most text editors start column numbers from 1, so you should subtract 1 from those column numbers.
* MaxDateDiff \[Float\] - The maximum difference in seconds between two entries' date fields for them to be combined.
