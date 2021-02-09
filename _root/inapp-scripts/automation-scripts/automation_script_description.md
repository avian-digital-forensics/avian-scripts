# Automation script
Avian auto-processing can run arbitrary Ruby scripts, but to be able to do so, the scripts must be of a specific format.

For a script called 'Example Script', the code looks as follows:
```
module ExampleScript
    extend self

    def run(nuix_case, utilities, settings_hash, progress_handler)
        # Run script here.
    end
end
```
There must be a `run` method taking 4 arguments in the `ScriptName` module placed in the file `script_name.rb`.

The 4 arguments are there to give the script access to the Nuix case, auto-processing logging and any custom settings the script might call for.
* `nuix_case`: This argument is a reference to the `Case` object representing the Nuix case being processed.
This allows the script to make all the changes a normal Nuix in-app script could.
* `utilities`: A reference to the Nuix `Utilities` object which is necessary for much of the API functionality provided by Nuix.
* `settings_hash`: A custom hash of settings specific for this script.
None of these are checked by the auto-processing, so this should obviously be done by the script and the script should also provide some documentation of the required/available options.
For an example of this, see the [Avian automation script documentation ](https://github.com/avian-digital-forensics/avian-scripts/blob/master/_root/inapp-scripts/automation-scripts/script_descriptions.md).
* `progress_handler`: An object that has many of the same methods as Nuix's `ProgressDialog` class, though many of them will do nothing.
This is to allow easier conversion of Nuix in-app scripts to Avian auto-processing scripts.
The most important method is `log_message`.
