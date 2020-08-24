# Load Timer
Adds custom metadata to each item telling when the item was loaded (both in absolute time and relative to load start), what item was loaded just before it by the same worker, and roughly how long it took to load.
Also creates a CSV-file with the following information about each item:
* GUID
* Time since previous item (load time). NIL if unavailable.
* MIME type
* GUID of parent item. NIL if this is unavailable
* File size. NIL if this is unavailable
* Path
* Time stamp

The CSV-file is updated live as the items are processed.

## Remarks
The timings are done by recording the time when the script is called for each item.
It is unknown when in the process of loading the item this happens, which makes the times given uncertain.
Especially the load times for the first items are imprecise.