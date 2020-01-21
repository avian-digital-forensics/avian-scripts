# Tag Exchange Emails with Duplicates
Background
Some organizations use archiving solutions to archive emails+attachments of some  emails in order to save live Exchange server storage. I.e. only the emails and not the attachments are included when acquiring PSTs from Exchange. When you acquire the archive PSTs from the archiving solution and mix in with the PSTs from the Exchange Server you will get a lot of duplicates. 

By assigning custom metadata to the emails from Exhange where a duplicate in the archive PST is found it's possible to exclude the duplicate emails from the dataset. 

How it works
Tags all emails starting with a specified text string as being exchange server emails.
Then gives all these emails a custom metadata field saying whether there is another email with the same ID among the non-exchange server emails.

The tags and custom metadata fields are customizable through the GUI.
