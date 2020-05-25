# Useful resources
## Worker Side Scripting: 
https://github.com/kalapakim/SmackDown2016/wiki/Worker-Side-Scripting

## Nuix Github: 
https://github.com/Nuix
Nuix's official Github with many pre-made scripts and libraries.
The scripts can both be useful as they are and as a way of discovering Nuix features that aren't easy to find.

## API docs:
Can be found by selecting Help/Help Topics in the Nuix GUI and selecting Scripting/Scripting API Docs from there.
See below for a note on variable names.

# Reload individual items
It is possible to reload individual items.
Use this to test WSS's.

When you try to do this, you might see that the option is greyed out in the item's context menu.
This is because the boxes to the items' left must be ticked for the option to be available.

# Use ruby
Not everything is supported in python (for example __file__), and Javascript (ECMAScript) is terrible.
(It may be possible to circumvent this in python by using 'inspect.getfile(inspect.currentframe())')
Nuix 8.0 uses ruby v2.3.3

# Ruby scripts are slow to start...
Any time an in-app ruby script is run, including from the console, Nuix waits a few seconds before doing so.
This seems to be because the ruby engine needs to start up each time.
I have written to Nuix support about it and was told that they were looking into it.

# Updates in required files not working in console
This happens for me the rare times it doesn't take far too long for the script to run.
This might be because the ruby engine is already running and it therefore doesn't reload files it already has required.
To work around this, switching to python (or ECMAScript) and back again seems to work.

# Use NX to create GUI's for your scripts
There is an open source library called NX for making GUI's for in-app scripts.
Especially useful is ProgressDialog.

# Use standard ruby naming conventions
Even though the documentation shows names like getItemGuid, everything has been aliased to idiomatic ruby names like item_guid, so these should be used instead.
This includes the GUI library.

# Print script progress
All in-app scripts should print their progress often.
This is useful when trying to find out when the scripts misbehave as well as being nice for the viewer.

# Errors in WSSs
## How to stop processing
When a WSS fails, Nuix won't tell you in the processing screen.
Instead processing will just stall.
To check whether this has happened, look in the logs.
If it has, the only solution is to cancel processing, but beware!
If you choose to 'stop' processing once such an error has occured, Nuix might not be closeable.
Instead, choose to 'abort'.
This will close the case and resume processing next time you open the case.
This is often fine, since you can edit the required files and try again.
If you don't want this, then repoen the case and _before the WSS fails_, 'stop' processing.

# WSS error messages aren't where you think they are
When debugging it is very useful to print messages.
For WSS's it can be difficult to see where these messages end up.
To find them select Help/Open Log Directory in the Nuix GUI.
This will open the log directory for you're current session.
From here open the most recently modified directory.
This is the log directory for the most recent load.
Inside, there should be one directory for every worker.
The log output (both normal and STDERR) of WSS's should be inside nuix.log inside each of these directories.

# Use BulkAnnotater when tagging many items
Do not loop through many items and tag them individually.
Use BulkAnnotater for this as it is far, far faster.

# Kind, type, and MIME
Type and MIME-type are the same.
Technically _nothing_ in Nuix is strictly MIME-types.
When MIME is refered to, it actually refers to Nuix's own type system that is close to MIME, but not identical.
A kind is a group of types.
Any item with one of these types is of that kind.
