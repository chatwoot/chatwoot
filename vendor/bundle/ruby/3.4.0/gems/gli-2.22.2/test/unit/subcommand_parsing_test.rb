require_relative "test_helper"
require_relative "support/fake_std_out"

class SubcommandParsingTest < Minitest::Test
  include TestHelper

  def setup
    @fake_stdout = FakeStdOut.new
    @fake_stderr = FakeStdOut.new

    @original_stdout = $stdout
    $stdout = @fake_stdout
    @original_stderr = $stderr
    $stderr = @fake_stderr

    @app = CLIApp.new
    @app.reset
    @app.subcommand_option_handling :legacy
    @app.error_device=@fake_stderr
    ENV.delete('GLI_DEBUG')

    @results = {}
    @exit_code = 0
  end

  def teardown
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  def test_commands_options_may_clash_with_globals_and_it_gets_sorted_out
    setup_app_with_subcommands_storing_results
    @app.run(%w(-f global command1 -f command -s foo))
    assert_equal  'command1',@results[:command_name]
    assert_equal  'global',  @results[:global_options][:f],'global'
    assert       !@results[:global_options][:s]
    assert_equal  'command', @results[:command_options][:f]
    assert        @results[:command_options][:s]
  end

  def test_in_legacy_mode_subcommand_options_all_share_a_namespace
    setup_app_with_subcommands_storing_results
    @app.run(%w(-f global command1 -f command -s subcommand10 -f sub))
    with_clue {
      assert_equal  'subcommand10',@results[:command_name]
      assert_equal  'global',      @results[:global_options][:f],'global'
      assert       !@results[:global_options][:s]
      assert_equal  'sub', @results[:command_options][:f]
      assert        @results[:command_options][:s]
      assert_nil    @results[:command_options][GLI::Command::PARENT]
      assert_nil    @results[:command_options][GLI::Command::PARENT]
    }
  end

  def test_in_normal_mode_each_subcommand_has_its_own_namespace
    setup_app_with_subcommands_storing_results :normal
    @app.run(%w(-f global command1 -f command -s subcommand10 -f sub))
    with_clue {
      assert_equal  'subcommand10',@results[:command_name]
      assert_equal  'global',      @results[:global_options][:f],'global'
      assert       !@results[:global_options][:s]
      assert_equal  'sub', @results[:command_options][:f]
      assert       !@results[:command_options][:s]
      assert_equal  'command',@results[:command_options][GLI::Command::PARENT][:f]
      assert        @results[:command_options][GLI::Command::PARENT][:s]
    }
  end

  def test_in_loose_mode_with_autocomplete_false_it_doesnt_autocorrect_a_sub_command
    setup_app_with_subcommand_storing_results :normal, false, :loose
    @app.run(%w(-f global command -f flag -s subcomm  -f subflag))
    with_clue {
      assert_equal "command",@results[:command_name]
    }
  end

  def test_in_strict_mode_with_autocomplete_false_it_doesnt_autocorrect_a_sub_command
    setup_app_with_subcommand_storing_results :normal, false, :strict
    @app.run(%w(-f global command -f flag -s subcomm  -f subflag))
    with_clue {
      assert       @fake_stderr.contained?(/expected no arguments, but received 3/)
      assert_equal nil,@results[:command_name]
    }
  end

  def test_in_loose_mode_argument_validation_is_ignored
    setup_app_with_arguments 1, 1, false, :loose
    run_app_with_X_arguments 0
    with_clue {
      assert_equal 0, @results[:number_of_args_give_to_action]
      assert_equal 0, @exit_code
    }
  end

  def test_in_strict_mode_subcommand_option_handling_must_be_normal
    setup_app_with_arguments 1, 1, false, :strict, :legacy
    run_app_with_X_arguments 1
    with_clue {
      assert_nil      @results[:number_of_args_give_to_action]
      assert_equal 1, @exit_code
      assert          @fake_stderr.contained?(/you must enable normal subcommand_option_handling/)
    }
  end

  [
    [1 , 1 , false , 1  ]    ,
    [1 , 1 , false , 2  ]    ,
    [1 , 1 , true  , 1  ]    ,
    [1 , 1 , true  , 2  ]    ,
    [1 , 1 , true  , 3  ]    ,
    [1 , 1 , true  , 30 ]    ,
    [0 , 0 , false , 0  ]    ,
    [0 , 1 , false , 1  ]    ,
    [0 , 1 , false , 0  ]    ,
    [1 , 0 , false , 1  ]    ,
    [0 , 0 , true  , 0  ]    ,
    [0 , 0 , true  , 10 ]

  ].each do |number_required, number_optional, has_multiple, number_generated|
    define_method "test_strict_options_success_cases_#{number_required}_#{number_optional}_#{has_multiple}_#{number_generated}" do
      setup_app_with_arguments number_required, number_optional, has_multiple, :strict
      run_app_with_X_arguments number_generated
      with_clue {
        assert_equal number_generated, @results[:number_of_args_give_to_action]
        assert_equal 0, @exit_code
        assert !@fake_stderr.contained?(/expected at least/)
        assert !@fake_stderr.contained?(/expected only/)
      }
    end
  end

  [
    [1 , 1 , false , 3  , :too_many]   ,
    [0 , 0 , false , 1  , :too_many]   ,
    [1 , 1 , false , 0  , :not_enough] ,
    [1 , 1 , true  , 0  , :not_enough] ,
    [1 , 0 , false , 0  , :not_enough] ,

  ].each do |number_required, number_optional, has_multiple, number_generated, status|
    define_method "test_strict_options_failure_cases_#{number_required}_#{number_optional}_#{has_multiple}_#{number_generated}_#{status}" do
      setup_app_with_arguments number_required, number_optional, has_multiple, :strict
      run_app_with_X_arguments number_generated
      with_clue {
        if status == :not_enough then
          assert_nil @results[:number_of_args_give_to_action]
          assert_equal 64, @exit_code
          assert @fake_stderr.contained?(/expected at least #{number_required} arguments, but was given only #{number_generated}/)
        elsif status == :too_many then
          assert_nil @results[:number_of_args_give_to_action]
          assert_equal 64, @exit_code
          if number_required == 0
            assert @fake_stderr.contained?(/expected no arguments, but received #{number_generated}/)
          else
            assert @fake_stderr.contained?(/expected only #{number_required + number_optional} arguments, but received #{number_generated}/)
          end
        else
          assert false
        end
      }
    end
  end

private
  def with_clue(&block)
    block.call
  rescue Exception
    dump = ""
    PP.pp "\nRESULTS---#{@results}", dump unless @results.empty?
    PP.pp "\nSTDERR---\n#{@fake_stderr.to_s}", dump
    PP.pp "\nSTDOUT---\n#{@fake_stdout.to_s}", dump
    @original_stdout.puts dump
    raise
  end

  def setup_app_with_subcommand_storing_results(subcommand_option_handling_strategy, autocomplete, arguments_handling_strategy)
    @app.subcommand_option_handling subcommand_option_handling_strategy
    @app.autocomplete_commands autocomplete
    @app.arguments arguments_handling_strategy
    @app.flag ['f','flag']
    @app.switch ['s','switch']

    @app.command "command" do |c|
      c.flag ['f','flag']
      c.switch ['s','switch']
      c.action do |global,options,args|
        @results = {
          :command_name => "command",
          :global_options => global,
          :command_options => options,
          :args => args
        }
      end

      c.command "subcommand" do |subcommand|
        subcommand.flag ['f','flag']
        subcommand.flag ['foo']
        subcommand.switch ['s','switch']
        subcommand.action do |global,options,args|
          @results = {
            :command_name => "subcommand",
            :global_options => global,
            :command_options => options,
            :args => args
          }
        end
      end
    end
  end

  def setup_app_with_subcommands_storing_results(subcommand_option_handling_strategy = :legacy)
    @app.subcommand_option_handling subcommand_option_handling_strategy
    @app.flag ['f','flag']
    @app.switch ['s','switch']

    2.times do |i|
      @app.command "command#{i}" do |c|
        c.flag ['f','flag']
        c.switch ['s','switch']
        c.action do |global,options,args|
          @results = {
            :command_name => "command#{i}",
            :global_options => global,
            :command_options => options,
            :args => args
          }
        end

        2.times do |j|
          c.command "subcommand#{i}#{j}" do |subcommand|
            subcommand.flag ['f','flag']
            subcommand.flag ['foo']
            subcommand.switch ['s','switch']
            subcommand.action do |global,options,args|
              @results = {
                :command_name => "subcommand#{i}#{j}",
                :global_options => global,
                :command_options => options,
                :args => args
              }
            end
          end
        end
      end
    end
  end

  def setup_app_with_arguments(number_required_arguments, number_optional_arguments, has_argument_multiple, arguments_handling_strategy = :loose, subcommand_option_handling_strategy = :normal)
    @app.arguments arguments_handling_strategy
    @app.subcommand_option_handling subcommand_option_handling_strategy

    number_required_arguments.times { |i| @app.arg("needed#{i}") }
    number_optional_arguments.times { |i| @app.arg("optional#{i}", :optional) }
    @app.arg :multiple, [:multiple, :optional] if has_argument_multiple

    @app.command :cmd do |c|
      c.action do |g,o,a|
        @results = {
          :number_of_args_give_to_action => a.size
        }
      end
    end
  end

  def run_app_with_X_arguments(number_arguments)
    @exit_code = @app.run [].tap{|args| args << "cmd"; number_arguments.times {|i| args << "arg#{i}"}}
  end
end
