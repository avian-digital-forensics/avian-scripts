# Ingest Fixed Width as CSV
All fixed width files that have been set up using '[Setup Ingest Fixed Width as CSV](../../avian-inapp-scripts/setup-ingest-fixed-width-as-csv.nuixscript)' receive a child item with the same data in CSV format.
Make sure to turn on CSV descendants under "MIME type settings/Spreadsheets" in the processing settings to make use of Nuix' special CSV functionality.
Nuix will then create an item for every entry in the CSV file.
Normally these items would be database row items, but this script gives them a communication and turns them into messages.
