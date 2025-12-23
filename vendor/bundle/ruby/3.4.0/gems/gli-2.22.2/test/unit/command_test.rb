require_relative "test_helper"
require_relative "support/fake_std_out"

class CommandTest < Minitest::Test
  include TestHelper
  def setup
    @fake_stdout = FakeStdOut.new
    @fake_stderr = FakeStdOut.new
    @original_stdout = $stdout
    $stdout = @fake_stdout
    @original_stderr = $stderr
    $stderr = @fake_stderr
    ENV.delete('GLI_DEBUG')
    create_app
  end

  def teardown
    $stdout = @original_stdout
    $stderr = @original_stderr
    FileUtils.rm_f "cruddo.rdoc"
  end

  def test_names
    command = GLI::Command.new(:names => [:ls,:list,:'list-them-all'],:description => "List")
    assert_equal "ls, list, list-them-all",command.names
  end

  def test_command_sort
    commands = [GLI::Command.new(:names => :foo)]
    commands << GLI::Command.new(:names => :bar)
    commands << GLI::Command.new(:names => :zazz)
    commands << GLI::Command.new(:names => :zaz)

    sorted = commands.sort
    assert_equal :bar,sorted[0].name
    assert_equal :foo,sorted[1].name
    assert_equal :zaz,sorted[2].name
    assert_equal :zazz,sorted[3].name
  end

  def test_basic_command
    [false,true].each do |openstruct|
      create_app(openstruct)
      openstruct_message = openstruct ? ", with use_openstruct" : ""
      args_args = [%w(-g basic -v -c foo bar baz quux), %w(-g basic -v --configure=foo bar baz quux)]
      args_args.each do |args|
        args_orig = args.clone
        @app.run(args)
        assert_equal('true',@glob,"For args #{args_orig}#{openstruct_message}")
        assert_equal('true',@glob_long_form,"For args #{args_orig}#{openstruct_message}")
        assert_equal('true',@verbose,"For args #{args_orig}#{openstruct_message}")
        assert_equal('false',@glob_verbose,"For args #{args_orig}#{openstruct_message}")
        assert_equal('foo',@configure,"For args #{args_orig}#{openstruct_message}")
        assert_equal(%w(bar baz quux),@args,"For args #{args_orig}#{openstruct_message}")
        assert(@pre_called,"Pre block should have been called for args #{args_orig}#{openstruct_message}")
        assert(@post_called,"Post block should have been called for args #{args_orig}#{openstruct_message}")
        assert(!@error_called,"Error block should not have been called for args #{args_orig}#{openstruct_message}")
      end
    end
  end

  def test_openstruct_with_nested_commands
    create_app(true)
    @app.run(["top","nested"])
    assert(!@error_called,"Error block should not have been called: #{@exception_caught.inspect}")
  end

  def test_around_filter
    @around_block_called = false
    @app.around do |global_options, command, options, arguments, code|
      @around_block_called = true
      code.call
    end
    @app.run(['bs'])
    assert(@around_block_called, "Wrapper block should have been called")
  end

  def test_around_filter_can_be_skipped
    # Given
    @around_block_called = false
    @action_called = false
    @app.skips_around
    @app.command :skips_around_filter do |c|
      c.action do |g,o,a|
        @action_called = true
      end
    end

    @app.command :uses_around_filter do |c|
      c.action do |g,o,a|
        @action_called = true
      end
    end

    @app.around do |global_options, command, options, arguments, code|
      @around_block_called = true
      code.call
    end

    # When
    exit_status = @app.run(['skips_around_filter'])

    # Then
    assert_equal 0,exit_status
    assert(!@around_block_called, "Wrapper block should have been skipped")
    assert(@action_called,"Action should have been called")

    # When
    @around_block_called = false
    @action_called = false
    exit_status = @app.run(['uses_around_filter'])

    # Then
    assert_equal 0, exit_status
    assert(@around_block_called, "Wrapper block should have been called")
    assert(@action_called,"Action should have been called")
  end

  def test_around_filter_can_be_nested
    @calls = []

    @app.around do |global_options, command, options, arguments, code|
      @calls << "first_pre"
      code.call
      @calls << "first_post"
    end

    @app.around do |global_options, command, options, arguments, code|
      @calls << "second_pre"
      code.call
      @calls << "second_post"
    end

    @app.around do |global_options, command, options, arguments, code|
      @calls << "third_pre"
      code.call
      @calls << "third_post"
    end

    @app.command :with_multiple_around_filters do |c|
      c.action do |g,o,a|
        @calls << "action!"
      end
    end

    @app.run(['with_multiple_around_filters'])

    assert_equal ["first_pre", "second_pre", "third_pre", "action!", "third_post", "second_post", "first_post"], @calls
  end

  def test_skipping_nested_around_filters
    @calls = []

    @app.around do |global_options, command, options, arguments, code|
      begin
        @calls << "first_pre"
        code.call
      ensure
        @calls << "first_post"
      end
    end

    @app.around do |global_options, command, options, arguments, code|
      @calls << "second_pre"
      code.call
      @calls << "second_post"
    end

    @app.around do |global_options, command, options, arguments, code|
      @calls << "third_pre"
      code.call
      exit_now!
      @calls << "third_post"
    end

    @app.command :with_multiple_around_filters do |c|
      c.action do |g,o,a|
        @calls << "action!"
      end
    end

    @app.run(['with_multiple_around_filters'])

    assert_equal ["first_pre", "second_pre", "third_pre", "action!", "first_post"], @calls
  end

  def test_around_filter_handles_exit_now
    @around_block_called = false
    @error_message = "OH NOES"
    @app.around do |global_options, command, options, arguments, code|
      @app.exit_now! @error_message
      code.call
    end
    exit_code = @app.run(['bs'])
    assert exit_code != 0
    assert_contained(@fake_stderr,/#{@error_message}/)
    assert_not_contained(@fake_stdout,/SYNOPSIS/)
  end

  def test_around_filter_handles_help_now
    @around_block_called = false
    @error_message = "OH NOES"
    @app.around do |global_options, command, options, arguments, code|
      @app.help_now! @error_message
      code.call
    end
    exit_code = @app.run(['bs'])
    assert exit_code != 0
    assert_contained(@fake_stderr,/#{@error_message}/)
    assert_contained(@fake_stdout,/SYNOPSIS/)
  end

  def test_error_handler_prints_that_its_skipping_when_gli_debug_is_set
    ENV["GLI_DEBUG"] = 'true'
    @app.on_error do
      false
    end
    @app.command :blah do |c|
      c.action do |*|
        raise 'wtf'
      end
    end

    assert_raises(RuntimeError) {
      @app.run(['blah'])
    }
    assert_contained(@fake_stderr,/Custom error handler exited false, skipping normal error handling/)
  end

  def test_error_handler_should_be_called_on_help_now
    @app.command :blah do |c|
      c.action do |*|
        help_now!
      end
    end
    @app.run(["blah"])
    assert @error_called
  end

  def test_error_handler_shouldnt_be_called_on_help_from_command_line
    @app.command :blah do |c|
      c.action do |*|
      end
    end
    [
      ["--help", "blah"],
      ["blah", "--help"],
    ].each do |args|
      args_copy = args.clone
      @app.run(args)
      assert !@error_called, "for args #{args_copy.inspect}"
    end
  end

  def test_command_skips_pre
    @app.skips_pre
    @app.skips_post

    skips_pre_called = false
    runs_pre_called = false

    @app.command [:skipspre] do |c| 
      c.action do |g,o,a|
        skips_pre_called = true
      end
    end

    # Making sure skips_pre doesn't leak to other commands
    @app.command [:runspre] do |c|
      c.action do |g,o,a|
        runs_pre_called = true
      end
    end

    @app.run(['skipspre'])

    assert(skips_pre_called,"'skipspre' should have been called")
    assert(!@pre_called,"Pre block should not have been called")
    assert(!@post_called,"Post block should not have been called")
    assert(!@error_called,"Error block should not have been called")

    @app.run(['runspre'])

    assert(runs_pre_called,"'runspre' should have been called")
    assert(@pre_called,"Pre block should not have been called")
    assert(@post_called,"Post block SHOULD have been called")
    assert(!@error_called,"Error block should not have been called")
  end

  def test_command_no_globals
    args = %w(basic -c foo bar baz quux)
    @app.run(args)
    assert_equal('foo',@configure)
    assert_equal(%w(bar baz quux),@args)
  end

  def test_defaults_get_set
    args = %w(basic bar baz quux)
    @app.run(args)
    assert_equal('false',@glob)
    assert_equal('false',@verbose)
    assert_equal('crud',@configure)
    assert_equal(%w(bar baz quux),@args)
  end

  def test_negatable_gets_created
    @app.command [:foo] do |c|
      c.action do |g,o,a|
        assert !g[:blah]
      end
    end
    exit_status = @app.run(%w(--no-blah foo))
    assert_equal 0,exit_status
  end

  def test_arguments_are_not_frozen
    @args = []


    @app.command [:foo] do |c|
      c.action do |g,o,a|
        @args = a
      end
    end
    exit_status = @app.run(%w(foo a b c d e).map { |arg| arg.freeze })
    assert_equal 0,exit_status
    assert_equal 5,@args.length,"Action block was not called"

    @args.each_with_index do |arg,index|
      assert !arg.frozen?,"Expected argument at index #{index} to not be frozen"
    end
  end

  def test_no_arguments
    args = %w(basic -v)
    @app.run(args)
    assert_equal('true',@verbose)
    assert_equal('crud',@configure)
    assert_equal([],@args)
  end

  def test_unknown_command
    args = %w(blah)
    @app.run(args)
    assert(!@post_called)
    assert(@error_called)
    assert_contained(@fake_stderr,/Unknown command 'blah'/)
  end

  def test_unknown_global_option
    args = %w(--quux basic)
    @app.run(args)
    assert(!@post_called)
    assert(@error_called,"Expected error callback to be called")
    assert_contained(@fake_stderr,/Unknown option --quux/)
  end

  def test_unknown_argument
    args = %w(basic --quux)
    @app.run(args)
    assert(!@post_called)
    assert(@error_called)
    assert_contained(@fake_stderr,/ Unknown option --quux/)
  end

  def test_forgot_action_block
    @app.reset
    @app.command :foo do
    end

    ENV['GLI_DEBUG'] = 'true'
    assert_raises RuntimeError do
      @app.run(['foo'])
    end
    assert_match /Command 'foo' has no action block/,@fake_stderr.to_s
  end

  def test_command_create
    @app.desc 'single symbol'
    @app.command :single do |c|; end
    command = @app.commands[:single]
    assert_equal :single, command.name
    assert_equal nil, command.aliases
  
    description = 'implicit array'
    @app.desc description
    @app.command :foo, :bar do |c|; end
    command = @app.commands[:foo]
    assert_equal :foo, command.name
    assert_equal [:bar], command.aliases

    description = 'explicit array'
    @app.desc description
    @app.command [:baz, :blah] do |c|; end
    command = @app.commands[:baz]
    assert_equal :baz, command.name
    assert_equal [:blah], command.aliases
  end

  def test_pre_exiting_false_causes_nonzero_exit
    @app.pre { |*| false }

    assert_equal 65,@app.run(["bs"]) # BSD for "input data incorrect in some way"
    assert_equal 'error: preconditions failed',@fake_stderr.to_s
    assert_equal '',@fake_stdout.to_s
  end

  def test_name_for_help_with_top_command
    @app.subcommand_option_handling :normal
    @app.command :remote do |c|; end
    command = @app.commands[:remote]
    assert_equal ["remote"], command.name_for_help
  end

  def test_name_for_help_with_sub_command
    @app.subcommand_option_handling :normal
    @app.command :remote do |c|
      c.command :add do |s|; end
    end
    sub_command = @app.commands[:remote].commands[:add]
    assert_equal ["remote", "add"], sub_command.name_for_help
  end


  def test_name_for_help_with_sub_sub_command
    @app.subcommand_option_handling :normal
    @app.command :remote do |c|
      c.command :add do |s|
        s.command :sub do |ss|; end
      end
    end
    sub_command = @app.commands[:remote].commands[:add].commands[:sub]
    assert_equal ["remote", "add", "sub"], sub_command.name_for_help
  end

  private

  def assert_contained(output,regexp)
    refute_nil output.contained?(regexp),
      "Expected output to contain #{regexp.inspect}, output was:\n#{output}"
  end

  def assert_not_contained(output,regexp)
    assert_nil output.contained?(regexp),
      "Didn't expected output to contain #{regexp.inspect}, output was:\n#{output}"
  end

  def create_app(use_openstruct=false)
    @app = CLIApp.new
    @app.error_device=@fake_stderr
    @app.reset
    
    if use_openstruct
      @app.use_openstruct true
    end

    @app.program_desc 'A super awesome program'
    @app.desc 'Some Global Option'
    @app.switch [:g,:global]
    @app.switch :blah
    @app.long_desc 'This is a very long description for a flag'
    @app.flag [:y,:yes]
    @pre_called = false
    @post_called = false
    @error_called = false
    @exception_caught = nil
    @app.pre { |g,c,o,a| @pre_called = true }
    @app.post { |g,c,o,a| @post_called = true }
    @app.on_error { |exception| @error_called = true; @exception_caught = exception }
    @glob = nil
    @verbose = nil
    @glob_verbose = nil
    @configure = nil
    @args = nil
    @app.desc 'Some Basic Command that potentially has a really really really really really really really long description and stuff, but you know, who cares?'
    @app.long_desc 'This is the long description: "Some Basic Command that potentially has a really really really really really really really long description and stuff, but you know, who cares?"'
    @app.arg_name 'first_file second_file'
    @app.command [:basic,:bs] do |c|
      c.desc 'be verbose'
      c.switch :v
      c.desc 'configure something or other, in some way that requires a lot of verbose text and whatnot'
      c.default_value 'crud'
      c.flag [:c,:configure]
      c.action do |global_options,options,arguments|
        if use_openstruct
          @glob           = global_options.g      ? 'true' : 'false'
          @glob_long_form = global_options.global ? 'true' : 'false'
          @verbose        = options.v             ? 'true' : 'false'
          @glob_verbose   = global_options.v      ? 'true' : 'false'
          @configure      = options.c
        else
          @glob           = global_options[:g]      ? 'true' : 'false'
          @glob_long_form = global_options[:global] ? 'true' : 'false'
          @verbose        = options[:v]             ? 'true' : 'false'
          @glob_verbose   = global_options[:v]      ? 'true' : 'false'
          @configure      = options[:c]
        end
        @args = arguments
      end
    end
    @app.desc "Testing long help wrapping"
    @app.long_desc <<-EOS
    This will create a scaffold command line project that uses @app
    for command line processing.  Specifically, this will create
    an executable ready to go, as well as a lib and test directory, all
    inside the directory named for your project
    EOS
    @app.command [:test_wrap] do |c|
      c.action {}
    end

    @app.desc "A top-level command"
    @app.command [:top] do |c|
      c.desc "A nested command"
      c.command [:nested] do |nested|
        nested.action {}
      end
    end
  end

end
