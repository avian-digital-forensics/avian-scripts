# QC and Culling
Automatically performs many of the processes involved in quality control.

1. Number of Descendants. Runs the script [NumberOfDescendants](#number-of-descendants) on the selected items.
This gives items a custom metadata field telling how many the descendants it has.
This information can be used in later steps.
2. Search and Tag. Runs NUIX' in-built search and tag functionality.
3. Culling. Excludes items with tags beginning with a specific prefixes.
4. Report. Writes some of the results of the above steps to an .rtf file.
