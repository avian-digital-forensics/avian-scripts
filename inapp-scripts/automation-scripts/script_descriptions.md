## Import Printed Images
Key: 'import_printed_images'

For every pdf in the source directory, finds the item with the right GUID and gives it the printed image.
### Settings
Settings in *italics* are optional.
* :main_directory - the path to the Avian scripts main directory.
* :source_path - path to the directory where the images to be imported are located.
* *:scoping_query* - only replaces the printed images for items matching this query, even if there are other pdf's in the source directory.
If left out, all items will be checked for a printed image.

## Number of Descendants
Key: 'number_of_descendants'

Gives every item in the scoping query a custom metadata value of how many descendants the item has.
### Settings
Settings in *italics* are optional.
* :main_directory - the path to the Avian scripts main directory.
* :metadata_key - the key for the custom metadata.
* *:scoping_query* - only runs for items matching this query. 
If left out, script will run on all items.

## Tag Exchange Emails with Duplicates
Key: 'tag_exchange_emails_with_duplicates'

<b>Background</b><br>
Some organizations use archiving solutions to archive emails+attachments of some  emails in order to save live Exchange server storage.
Therefore, only the emails and not the attachments are included when acquiring PSTs from Exchange.
When you acquire the archive PSTs from the archiving solution and mix in with the PSTs from the Exchange Server you will get a lot of duplicates. 

By assigning custom metadata to the emails from Exhange where a duplicate in the archive PST is found it's possible to exclude the duplicate emails from the dataset. 

<b>How it works</b><br>
Tags all emails starting with a specified text string as being exchange server emails.
Then gives all these emails a custom metadata field saying whether there is another email with the same ID among the non-exchange server emails.

### Settings
Settings in *italics* are optional.
* :main_directory - the path to the Avian scripts main directory.
* :archived_prefix - all emails containing this text will be treated as exchange server emails.
* :archived_tag - all emails containing the above prefix will receive this tag.
* :archived_has_duplicate_tag - all archived emails with duplicates will receive this tag.
* :archived_missing_duplicate_tag - all archived emails without duplicates will receive this tag.
* :has_missing_attachments_tag - all archived emails with children but no duplicate receive this tag.
* :exclude_archived_items_with_duplicates - all archived emails with duplicates will be excluded if this is set to true.

## QC and Culling
key: 'qc_cull'

Automatically performs many of the processes involved in quality control.

1. Number of Descendants. Runs the script [NumberOfDescendants](#number-of-descendants) on the selected items.
This gives items a custom metadata field telling how many the descendants it has.
This information can be used in later steps.
2. Search and Tag. Runs NUIX' in-built search and tag functionality.
3. Culling. Excludes items with tags beginning with a specific prefixes.
4. Report. Writes some of the results of the above steps to an .rtf file.

### Settings
Settings in *italics* are optional.
* :main_directory - the path to the Avian scripts main directory.
* :num_descendants_metadata_key - the name of the custom metadata given to items by the NumberOfDescendants script.
* :report_path - where to place the finished report.
* *:scoping_query* - only runs for items matching this query.
