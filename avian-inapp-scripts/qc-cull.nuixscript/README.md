# QC and Culling
Automatically runs many of the processes involved in quality control.
All the following steps are only performed on the selected items.

1. Number of Descendants. 
Runs the script NumberOfDescendants on the selected items.
This gives items a custom metadata field telling how many the descendants it has.
This information can be used in later steps.
The name of the tag can be chosen in the GUI.
2. Search and Tag.
Runs NUIX' in-built search and tag functionality with the Search and Tag .json files specified under the 'Search and Tag' tab.
Currently maxed at 5 such files, contact the developer if more are needed.
3. Culling.
Excludes items with tags beginning with a specific prefix.
The prefix and exclusion reason can both be set in the GUI.
