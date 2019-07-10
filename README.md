# Avian Scripts
A collection of all scripts for Nuix created by Avian

## Worker Side Scripts (WWS's)
All worker side scripts are located in the directory 'wss'.
WWS'es are run during loading of a case, and this allows them to do things regular scripts cannot.

### Usage
There are several ways to use a WWS, (see [here](https://github.com/kalapakim/SmackDown2016/wiki/Worker-Side-Scripting) for more information), but for Avian scripts, there is an especially easy way.
First download the entire repository to it's own directory.
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
