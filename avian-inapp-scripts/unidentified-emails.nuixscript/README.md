#Find and fix unidentified emails
Finds items that Nuix has not identified as emails, yet look like they should be.
These items are tagged, and a file is created that stores the items' communication information.
If the WSS '[Add Communication to Unidentified Emails](https://github.com/avian-digital-forensics/avian-scripts/tree/master/wss/add-communication-to-unidentified-emails)' is run, the items' MIME-types will be corrected and they will receive communication data.

If no items are selected a default search is run in "Find" and the found items are processed.