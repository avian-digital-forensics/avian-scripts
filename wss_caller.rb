def nuix_worker_item_callback(worker_item)
    # All text after a hashtag (#) is ignored, and is used for comments.
    # EDIT: The absolute path to the avian scripts directory.
    # The path may NOT end with a backslash.
    path = 'REPLACE WITH PATH TO DIRECTORY'
    
    # EDIT: List of all worker side scripts that should be executed, in order.
    # All available scripts are listed in the project readme on github.
    # This list is not case-sensitive,
    # and all spaces and underscores are ignored.
    # You can add as many as you like, just remember to end all lines but the last with a comma.
    scripts = [ 
    'example script one', 
    'example_script_two', 
    'eXample_scRiPtTHREe' 
    ]
    
    # Actually runs the scripts. Do not touch.
    path.chomp('/')
    path.chomp('\\')
    load (path + '/wss_dispatcher.rb')
    dispatch_scripts(path, scripts, worker_item)
end