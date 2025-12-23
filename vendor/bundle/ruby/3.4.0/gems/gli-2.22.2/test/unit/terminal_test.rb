require_relative "test_helper"

class TerminalTest < Minitest::Test
  include TestHelper

  # TODO: Make this test not mess with the internals of the class
  def xtest_command_exists
    assert GLI::Terminal.instance.command_exists?('ls')
    assert !GLI::Terminal.instance.command_exists?('asdfasfasdf')
  end

  def setup
    @old_columns = ENV['COLUMNS']
    @old_lines = ENV['LINES']
  end

  def teardown
    ENV['COLUMNS'] = @old_columns 
    ENV['LINES'] = @old_lines
    GLI::Terminal.default_size = [80,24]
  end

  def test_shared_instance_is_same
    assert_equal GLI::Terminal.instance,GLI::Terminal.instance
  end

  def test_size_based_on_columns
    ENV['COLUMNS'] = '666'
    ENV['LINES'] = '777'
    assert_equal [666,777],GLI::Terminal.instance.size
  end

  def test_size_using_tput
    terminal = GLI::Terminal.new
    terminal.make_unsafe!
    GLI::Terminal.instance_eval do
      def run_command(command)
        if command == 'tput cols'
          return '888'
        elsif command == 'tput lines'
          return '999'
        else
          raise "Unexpected command called: #{command}"
        end
      end
      def command_exists?(command); true; end
      def jruby?; true; end
    end
    ENV['COLUMNS'] = 'foo'
    assert_equal [888,999],terminal.size
  end

  def test_size_using_stty
    terminal = GLI::Terminal.new
    terminal.make_unsafe!
    GLI::Terminal.instance_eval do
      def run_command(command)

        if RUBY_PLATFORM == 'java'
          return '5678' if command == 'tput cols'
          return '1234' if command == 'tput lines'
        else 
          return '1234 5678' if command == 'stty size'
          return '1234 5678' if command == 'stty'
        end

        raise "Unexpected command called: #{command} for #{RUBY_PLATFORM}"
      end
      def command_exists?(command); true; end
      def jruby?; false; end
      def solaris?; false; end
    end
    ENV['COLUMNS'] = 'foo'
    assert_equal [5678,1234],terminal.size
  end

  def test_size_using_stty_but_returns_0
    terminal = GLI::Terminal.new
    terminal.make_unsafe!
    GLI::Terminal.instance_eval do
      def run_command(command)

        if RUBY_PLATFORM == 'java'
          return '0' if command == 'tput cols'
          return '0' if command == 'tput lines'
        else 
          return '0 0' if command == 'stty size'
          return '0 0' if command == 'stty'
        end

        raise "Unexpected command called: #{command} for #{RUBY_PLATFORM}"
      end
      def command_exists?(command); true; end
      def jruby?; false; end
      def solaris?; false; end
    end
    ENV['COLUMNS'] = 'foo'
    assert_equal [80,24],terminal.size
  end

  def test_size_using_default
    terminal = GLI::Terminal.new
    terminal.make_unsafe!
    GLI::Terminal.instance_eval do
      def command_exists?(command); false; end
      def jruby?; false; end
      def solaris?; false; end
    end
    ENV['COLUMNS'] = 'foo'
    assert_equal [80,24],terminal.size
    # While we have this set up, lets make sure the default change falls through
    GLI::Terminal.default_size = [90,45]
    assert_equal [90,45],terminal.size
  end

  def test_size_using_default_when_exception
    terminal = GLI::Terminal.new
    GLI::Terminal.instance_eval do
      def jruby?; raise "Problem"; end
      def solaris?; false; end
    end
    ENV['COLUMNS'] = 'foo'
    assert_equal [80,24],terminal.size
  end
end
