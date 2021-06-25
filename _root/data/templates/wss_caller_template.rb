# READ: Simply copy the entire contents of this file into the Worker Script text field in Nuix.
# Will only work if you have run the in-app script "Setup WSS's" correctly before hand.

PATH = 'HAS NOT BEEN SET UP'

def nuixWorkerItemCallbackInit
    unless File.directory?(PATH)
        STDERR.puts("Given path does not exist. Path: " + PATH)
    end
    load(PATH + '/wss_dispatcher.rb')
    run_init(PATH)
end

def nuixWorkerItemCallback(worker_item)
    run(worker_item)
end

def nuixWorkerItemCallbackClose
    run_close
end
