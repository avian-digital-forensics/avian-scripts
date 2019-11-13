module Timing
    # Provides a way of timing several different things with one object.
    class Timer
        def initialize
            @timers = {}
        end
        
        def running?(stop_watch_name)
            return @timers.key?(stop_watch_name) && @timers[stop_watch_name].running
        end
        
        def exist?(stop_watch_name)
            return @timers.key?(stop_watch_name)
        end
            
        def start(stop_watch_name)
            ensure_stop_watch(stop_watch_name)
            
            @timers[stop_watch_name].start
        end
        
        def stop(stop_watch_name)
            ensure_stop_watch(stop_watch_name)
            
            @timers[stop_watch_name].stop
        end
        
        def total_time(stop_watch_name)
            ensure_stop_watch(stop_watch_name)
            
            return @timers[stop_watch_name].total_time
        end
        
        def reset(stop_watch_name)
            ensure_stop_watch(stop_watch_name)
            
            @timers[stop_watch_name].reset
        end
        
        def print_timings(stop_watch_names: [], runs: 1)
            if stop_watch_names.empty? and not all_timers.empty?
                print_timings(stop_watch_names: all_timers, runs: runs)
            else
                puts("Timings:")
                for stop_watch_name in stop_watch_names
                    puts("    " + stop_watch_name + ": " + Timing.seconds_to_string(total_time(stop_watch_name)/runs))
                end
            end
        end
        def all_timers
            return @timers.keys
        end
            
        private
            def ensure_stop_watch(stop_watch_name)
                unless @timers.key?(stop_watch_name)
                    @timers[stop_watch_name] = StopWatch.new
                end 
            end
            
            # Round down to nearest whole number.
            # Not a great way of doing it, but simple.
            def round_down(x)
                # Converts the input to a string and removes everything after the decimal point.
                return x.to_s.split('.')[0].to_f
            end
    end
    
    # Provides a way of measuring time over multiple periods.
    class StopWatch
        # Initilizes a stop watch.
        def initialize
            @total_time = 0
            @cur_start = 0
            @running = false
        end
        
        # Starts the stop watch, but does not reset the time.
        # Will raise an exception if the stop watch is already running.
        def start
            if running?
                raise "Timer already running."
            end
            @cur_start = Time.now
            @running = true
        end
        
        # Stops the stop watch.
        # Will raise an exception if the stop watch is not running.
        def stop
            unless running?
                raise "Timer isn't running."
            end
            @total_time += Time.now - @cur_start
            @running = false
        end
        
        def running?
            return @running
        end
        
        # The total time measured since last reset.
        def total_time
            if running?
                return Time.now - @cur_start + @total_time
            else
                return @total_time
            end
        end
        
        # Resets the measured time to 0.
        def reset
            @cur_start = Time.now
            @total_time = 0
        end
    end
    
    # Round down to nearest whole number.
    # Not a great way of doing it, but simple.
    def self.round_down(x)
        x.to_i
    end
    
    # Takes a time span in seconds and returns hours, minutes, and seconds.
    def self.hours_and_minutes_from_seconds(total_seconds)
        hours = round_down(total_seconds / (60 * 60))
        minutes = round_down(total_seconds / 60) % 60
        seconds = total_seconds % 60
        return hours, minutes, seconds
    end

    # Returns a human readable string representation of the given time interval.
    def self.seconds_to_string(seconds)
        hours, minutes, seconds = hours_and_minutes_from_seconds(seconds)
        return hours.to_s + "h" + minutes.to_s + "m" + seconds.round(9).to_s + "s"
    end
end
