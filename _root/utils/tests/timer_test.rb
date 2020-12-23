require "test/unit"
require_relative '../timer'

class TestTimer < Test::Unit::TestCase
    def test_start_running
        timer = Timing::Timer.new
        timer.start('test')
        assert(timer.running?('test'))
        assert(!timer.running?('not_started'))
    end

    def test_stop
        timer = Timing::Timer.new
        timer.start('test')
        timer.start('not_stopped')
        assert(timer.running?('test'))
        timer.stop('test')
        assert(!timer.running?('test'))
        assert(timer.running?('not_stopped'))
    end

    def test_timing
        timer = Timing::Timer.new
        timer.start('test')
        sleep(0.1)
        timer.stop('test')
        assert(timer.total_time('test')>0.1)
    end

    def test_reset
        timer = Timing::Timer.new
        timer.start('test')
        sleep(0.1)
        timer.stop('test')
        timer.reset('test')
        assert_equal(0, timer.total_time('test'))
    end
end
