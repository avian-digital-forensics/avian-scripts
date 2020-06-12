module ProgressHandler
  class ProgressHandler
    def initialize
    end

    # Hands status to the on_message_logged callback.
    # Params:
    # +status+:: The message to pass the the callback.
    def set_main_status_and_log_it(status)
      @callback.call(status)
    end

    # Does nothing.
    # Params:
    # +value+:: The initial value of the progress bar in the progress dialog. Unused here.
    # +max+:: The maximum value of the progress bar in the progress dialog. Unused here.
    def set_main_progress(value, max)
    end

    # Does nothing.
    # Params:
    # +status+:: The substatus set in the progress dialog. Unused here.
    def set_substatus(status)
    end

    # Does nothing.
    def increment_main_progress
    end
    
    # Returns false.
    def abort_was_requested
      false
    end

    # Hands the message to the on_message_logged callback.
    # Params:
    # +message+:: The message to pass to the callback.
    def log_message(message)
      @callback.call(message)
    end

    # Does nothing.
    # Params:
    # +value+:: Whether sub progress bar/status should be visible in the progress dialog. Unused here.
    def set_sub_progress_visible(value)
    end

    # Sets the callback for printing messages.
    # Params:
    # +callback+:: Called every time a message is to be logged. Should take a single string as argument.
    def on_message_logged(&callback)
      @callback = callback
    end
  end
end
