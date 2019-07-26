# All text after a hashtag (#) is ignored, and is used for comments.
# Anywhere with uppercase 'edit' is a place you can edit.
# Please read these comments carefully, edit what they ask they to, and leave everything else alone.

# EDIT: The absolute path to the avian scripts directory.
# The path may NOT end with a backslash.
PATH = 'REPLACE WITH PATH TO DIRECTORY'

# EDIT: List of all worker side scripts that should be executed, in order.
# All available scripts are listed in the project readme on github.
# Simply copy their names into the list below.
# This list is not case-sensitive, and all spaces and underscores are ignored.
# You can add as many as you like, just remember to end all lines but the last with a comma.
SCRIPTS = [ 
'example script one', 
'example_script_two', 
'eXample_scRiPtTHREe' 
]

########################### DO NOT TOUCH #####################
# Everything below this line actually runs the scripts.
# Do not touch unless you know what you're doing.

def nuixWorkerItemCallbackInit
    load(PATH + '/wss_dispatcher.rb')
    run_init(PATH, SCRIPTS)
end

def nuixWorkerItemCallback(worker_item)
    run(worker_item)
end

def nuixWorkerItemCallbackClose
    run_close
end