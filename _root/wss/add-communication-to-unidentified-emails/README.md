# Add communication to unidentified emails
Uses the output of the in-app script '[FixUnidentifiedEmails](https://github.com/avian-digital-forensics/avian-scripts/tree/master/avian-inapp-scripts/unidentified-emails/fix-unidentified-emails.nuixscript)' to add communication information to items representing emails that haven't been identified by Nuix.
If that script hasn't been run on the items, this WSS will fail.

Some addresses may be changed to lower case.
It is not known why this happens, but the addresses given to Nuix have their cases preserved, so it must be some subtlety in Nuix.
