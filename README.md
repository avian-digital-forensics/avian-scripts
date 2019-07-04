# Avian Scripts
A collection of all scripts for Nuix created by Avian

## Worker Side Scripts (WWS's)
All worker side scripts are located in the directory 'wss'.
WWS'es are run during loading of a case, and this allows them to do things regular scripts cannot.

### Usage
There are several ways to use a WWS, (see [here](https://github.com/kalapakim/SmackDown2016/wiki/Worker-Side-Scripting) for more information), but probably the easiest way is to use the script `wssCaller.rb` found in this repository.
To use `wssCaller.rb`, start by downloading the entire repository or just `wssCaller.rb` and the WSS you're interested in.
It's very important that you know the location of the WSS file location.
When loading data, in the settings menu, there should be a tab called 'Worker Script' with a single huge text field.
Copy the contents of `wwsCaller.rb` into this field and set `scriptPath` to the path of the script you wish to run.
Now simply load the case as usual.

For details on a specific WSS please read the pertaining readme.