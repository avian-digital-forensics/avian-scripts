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
