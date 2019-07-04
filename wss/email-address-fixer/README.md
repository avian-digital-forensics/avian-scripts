# Fix microsoft exchange server email addresses.
The script finds all communications where the "From" address is a microsoft exchange server address, and replaces that address with the original readable email address.

## Before using the script
Before using this script there are a few optional settings.
They are all located just after the `if` in the function `nuixWorkerItemCallback`

* `levelMetadataName` the name of the custom metadata element used for debug information. 
Only used if `debugMode = true`.
This value says which method was used to find the address and roughly indicates how uncertain the corrected address is.
A value of 5 means no address was found.
* `fromEmailMetadataName` the name of the custom metadata element used for the corrected from emai address.
* `originalFromEmailMetadataName` the name of the custom metadata element used for the original exchange server address.
* `debugMode` whether to store debug information.

## Usage
This is a worker side script, so insert it into your case loading however.

## Notes
Because of the way the microsoft exchange emails look, it is not possible to guarantee that all emails will be fixed correctly.
This is partly why the original is always stored in custom metadata.