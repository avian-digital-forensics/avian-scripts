module ProgressHandler
  class ProgressHandler
    # Initializes the ProgressHandler with an optional log_callback.
    # Params:
    # +log_callback+:: A callback to be called every time a message is logged. Should take a single string argument.
    def initialize(&log_callback)
      @log_callbacks = []
      if block_given?
        @log_callbacks << log_callback
      end
    end

    # Hands status to the on_message_logged callback.
    # Params:
    # +status+:: The message to pass the the callback.
    def set_main_status_and_log_it(status)
      call_log_callbacks(status)
    end

    # Does nothing.
    # Params:
    # +value+:: The initial value of the progress bar in the progress dialog. Unused here.
    # +max+:: The maximum value of the progress bar in the progress dialog. Unused here.
    def set_main_progress(value, max)
    end

    # Does nothing.
    # Params:
    # +status+:: The sub status set in the progress dialog. Unused here.
    def set_sub_status(status)
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
      call_log_callbacks(message)
    end

    # Does nothing.
    # Params:
    # +value+:: Whether sub progress bar/status should be visible in the progress dialog. Unused here.
    def set_sub_progress_visible(value)
    end

    # Adds a callback for printing messages.
    # Params:
    # +callback+:: Called every time a message is to be logged. Should take a single string as argument.
    def on_message_logged(&callback)
      @log_callbacks << callback
    end

    private
      # Calls all stored log_callbacks with the given message
      # Params:
      # +message+:: The message to give to all callbacks.
      def call_log_callbacks(message)
        for callback in @log_callbacks
          callback.call(message)
        end
      end
  end
end
