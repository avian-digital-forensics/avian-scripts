# Avian Scripts
A collection of all scripts for Nuix created by Avian

## Setup
Use this link to get the newest version of the repository:
https://github.com/avian-digital-forensics/avian-scripts/archive/release.zip

Unpack the contents to an empty directory and follow the guides below.

## Scripts
This is about the scripts that are run from within Nuix, usually with a case already open.
To use them, first download the newest release version of the repository from the link in [Setup](##Setup).
In Nuix open the 'Scripts' menu and select 'Open Scripts Directory'.
From the Avian Scripts repository, copy the ´avian-inapp-scripts´ directory into the directory Nuix just opened.
Now simply run the scripts from the 'Scripts' menu under 'Nuix Developed Scripts'.

For details on a specific script please read the pertaining readme.

### Available in-app scripts
* Connected Addresses - creates a csv file with information about what addresses a specific address has sent messages to.

## Worker Side Scripts (WWS's)
All worker side scripts are located in the directory 'wss'.
WWS'es are run during loading of a case, and this allows them to do things regular scripts cannot.

### Usage
There are several ways to use a WWS, (see [here](https://github.com/kalapakim/SmackDown2016/wiki/Worker-Side-Scripting) for more information), but for Avian scripts, there is an especially easy way.
First download the newest release version of the repository from the link in [Setup](##Setup).
In the downloaded repository there is a file called `wss_caller.rb` in which you must set the `path` variable to the location of the downloaded repository.
When loading data, in the settings menu, there should be a tab called 'Worker Script' with a single huge text field.
Copy the contents of `wwsCaller.rb` (the file can be opened with any text editor like Notepad or Notepad++) into this field and edit the list of scripts to whichever scripts you like.
At the top, above the text field there is a choice between ECMAScript, python or ruby.
Choose ruby.

Now simply load the case as usual.

If any of the given script names cannot be matched to an available WSS, an error will be printed to the log.

For details on a specific WSS please read the pertaining readme.

### Available worker side scripts
* Email Address Fixer - replaces mangled microsoft exchange server email addresses with the original readable adresses.
