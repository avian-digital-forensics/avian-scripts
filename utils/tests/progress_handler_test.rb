require "test/unit"
require_relative '../progress_handler'

class TestProgressHandler < Test::Unit::TestCase
  def test_response
    progress_handler = ProgressHandler::ProgressHandler.new
    methods = ['set_main_status_and_log_it', 'set_main_progress', 
        'set_substatus', 'increment_main_progress', 'abort_was_requested',
        'log_message', 'set_sub_progress_visible', 'on_message_logged']
    for method in methods
      assert(progress_handler.respond_to?(method))
    end
  end

  def test_log
    progress_handler = ProgressHandler::ProgressHandler.new
    x = ''
    progress_handler.on_message_logged do |message|
      x += message
    end
    progress_handler.set_main_status_and_log_it('a')
    progress_handler.log_message('b')
    assert(x == 'ab')
  end
end
