require_relative "test_helper"

class HelpTest < Minitest::Test
  include TestHelper

  def setup
    @option_index = 0
    @real_columns = ENV['COLUMNS']
    ENV['COLUMNS'] = '1024'
    @output = StringIO.new
    @error = StringIO.new
    @command_names_used = []
    # Reset help command to its default state
    GLI::Commands::Help.skips_pre    = true
    GLI::Commands::Help.skips_post   = true
    GLI::Commands::Help.skips_around = true
  end

  def teardown
    ENV['COLUMNS'] = @real_columns
  end

  class TestApp
    include GLI::App
  end

  def test_help_command_configured_properly_when_created
    app = TestApp.new
    app.subcommand_option_handling :normal
    @command = GLI::Commands::Help.new(app,@output,@error)
    assert_equal   'help',@command.name.to_s
    assert_nil     @command.aliases
    assert_equal   'command',@command.arguments_description
    refute_nil @command.description
    refute_nil @command.long_description
    assert         @command.skips_pre
    assert         @command.skips_post
    assert         @command.skips_around
  end

  def test_the_help_command_can_be_configured_to_skip_things_declaratively
      app = TestApp.new
      app.subcommand_option_handling :normal
      @command = GLI::Commands::Help.new(app,@output,@error)
      GLI::Commands::Help.skips_pre    = false
      GLI::Commands::Help.skips_post   = false
      GLI::Commands::Help.skips_around = false
      assert !@command.skips_pre
      assert !@command.skips_post
      assert !@command.skips_around
  end

  def test_the_help_command_can_be_configured_to_skip_things_declaratively_regardless_of_when_the_object_was_created
      GLI::Commands::Help.skips_pre    = false
      GLI::Commands::Help.skips_post   = false
      GLI::Commands::Help.skips_around = false
      app = TestApp.new
      app.subcommand_option_handling :normal
      @command = GLI::Commands::Help.new(app,@output,@error)
      assert !@command.skips_pre
      assert !@command.skips_post
      assert !@command.skips_around
  end

  def test_invoking_help_with_no_arguments_results_in_listing_all_commands_and_global_options
    setup_GLI_app
      @command = GLI::Commands::Help.new(@app,@output,@error)
      @command.execute({},{},[])
      assert_top_level_help_output
  end

  def test_invoking_help_with_a_command_that_doesnt_exist_shows_an_error
    setup_GLI_app
      @command = GLI::Commands::Help.new(@app,@output,@error)
      @unknown_command_name = any_command_name
      @command.execute({},{},[@unknown_command_name])
      assert_error_contained(/error: Unknown command '#{@unknown_command_name}'./)
  end

  def test_invoking_help_with_a_known_command_shows_help_for_that_command
    setup_GLI_app
      @command_name = cm = any_command_name
      @desc         = d  = any_desc
      @long_desc    = ld = any_desc
      @switch       = s  = any_option
      @switch_desc  = sd = any_desc
      @flag         = f  = any_option
      @flag_desc    = fd = any_desc

      @app.instance_eval do
        desc d
        long_desc ld
        command cm do |c|

          c.desc sd
          c.switch s

          c.desc fd
          c.flag f

          c.action {}
        end
      end
      @command = GLI::Commands::Help.new(@app,@output,@error)
      @command.execute({},{},[@command_name])
      assert_output_contained(@command_name,"Name of the command")
      assert_output_contained(@desc,"Short description")
      assert_output_contained(@long_desc,"Long description")
      assert_output_contained("-" + @switch,"command switch")
      assert_output_contained(@switch_desc,"switch description")
      assert_output_contained("-" + @flag,"command flag")
      assert_output_contained(@flag_desc,"flag description")
  end

  def test_invoking_help_with_no_global_options_omits_the_global_options_placeholder_from_usage
    setup_GLI_app(:no_options)
      @command = GLI::Commands::Help.new(@app,@output,@error)
      @command.execute({},{},[])
      refute_output_contained(/\[global options\] command \[command options\] \[arguments\.\.\.\]/)
      refute_output_contained('GLOBAL OPTIONS')
      assert_output_contained(/command \[command options\] \[arguments\.\.\.\]/)
  end

  def test_invoking_help_with_a_known_command_when_no_global_options_are_present_omits_placeholder_from_the_usage_string
    setup_GLI_app(:no_options)
      @command_name = cm = any_command_name
      @desc         = d  = any_desc
      @long_desc    = ld = any_desc
      @switch       = s  = any_option
      @switch_desc  = sd = any_desc
      @flag         = f  = any_option
      @flag_desc    = fd = any_desc

      @app.instance_eval do
        desc d
        long_desc ld
        command cm do |c|

          c.desc sd
          c.switch s

          c.desc fd
          c.flag f

          c.action {}
        end
      end
      @command = GLI::Commands::Help.new(@app,@output,@error)
      @command.execute({},{},[@command_name])
      refute_output_contained(/\[global options\]/)
      assert_output_contained(/\[command options\]/)
      assert_output_contained('COMMAND OPTIONS')
  end

  def test_omits_both_placeholders_when_no_options_present
    setup_GLI_app(:no_options)
      @command_name = cm = any_command_name
      @desc         = d  = any_desc
      @long_desc    = ld = any_desc

      @app.instance_eval do
        desc d
        long_desc ld
        command cm do |c|
          c.action {}
        end
      end
      @command = GLI::Commands::Help.new(@app,@output,@error)
      @command.execute({},{},[@command_name])
      refute_output_contained(/\[global options\]/)
      refute_output_contained(/\[command options\]/)
      refute_output_contained('COMMAND OPTIONS')
  end

  def test_no_command_options_omits_command_options_placeholder
    setup_GLI_app
      @command_name = cm = any_command_name
      @desc         = d  = any_desc
      @long_desc    = ld = any_desc

      @app.instance_eval do
        desc d
        long_desc ld
        command cm do |c|
          c.action {}
        end
      end
      @command = GLI::Commands::Help.new(@app,@output,@error)
      @command.execute({},{},[@command_name])
      assert_output_contained(/\[global options\]/)
      refute_output_contained(/\[command options\]/)
      refute_output_contained('COMMAND OPTIONS')
  end

  def test_omitting_default_description_doesnt_blow_up
      app = TestApp.new
      app.instance_eval do
        subcommand_option_handling :normal
        command :top do |top|
          top.command :list do |list|
            list.action do |g,o,a|
            end
          end

          top.command :new do |new|
            new.action do |g,o,a|
            end
          end

          top.default_command :list
        end
      end
      @command = GLI::Commands::Help.new(app,@output,@error)
      begin
        @command.execute({},{},['top'])
      rescue => ex
        assert false, "Expected no exception, got: #{ex.message}"
      end
  end

private

  def setup_GLI_app(omit_options=false)
      @program_description = program_description = any_desc
      @flags = flags = [
        [any_desc.strip,:foo,[any_option]],
        [any_desc.strip,:bar,[any_option,any_long_option]],
      ]
      @switches = switches = [
        [any_desc.strip,[any_option]],
        [any_desc.strip,[any_option,any_long_option]],
      ]

      @commands = commands = [
        [any_desc.strip,[any_command_name]],
        [any_desc.strip,[any_command_name,any_command_name]],
      ]

      @app = TestApp.new
      @app.instance_eval do
        program_desc program_description
        subcommand_option_handling :normal

        unless omit_options
          flags.each do |(description,arg,flag_names)|
            desc description
            arg_name arg
            flag flag_names
          end

          switches.each do |(description,switch_names)|
            desc description
            switch switch_names
          end
        end

        commands.each do |(description,command_names)|
          desc description
          command command_names do |c|
            c.action {}
          end
        end
      end
  end

  def assert_top_level_help_output
    assert_output_contained(@program_description)

    @commands.each do |(description,command_names)|
      assert_output_contained(/#{command_names.join(', ')}\s+-\s+#{description}/,"For command #{command_names.join(',')}")
    end
    assert_output_contained(/help\s+-\s+#{@command.description}/)

    @switches.each do |(description,switch_names)|
      expected_switch_names = switch_names.map { |_| _.length == 1 ? "-#{_}" : "--\\[no-\\]#{_}" }.join(', ')
      assert_output_contained(/#{expected_switch_names}\s+-\s+#{description}/,"For switch #{switch_names.join(',')}")
    end

    @flags.each do |(description,arg,flag_names)|
      expected_flag_names = flag_names.map { |_| _.length == 1 ? "-#{_}" : "--#{_}" }.join(', ')
      assert_output_contained(/#{expected_flag_names}[ =]#{arg}\s+-\s+#{description}/,"For flag #{flag_names.join(',')}")
    end

    assert_output_contained('GLOBAL OPTIONS')
    assert_output_contained('COMMANDS')
    assert_output_contained(/\[global options\] command \[command options\] \[arguments\.\.\.\]/)
  end

  def assert_error_contained(string_or_regexp,desc='')
    string_or_regexp = /#{string_or_regexp}/ if string_or_regexp.kind_of?(String)
    assert_match string_or_regexp,@error.string,desc
  end

  def assert_output_contained(string_or_regexp,desc='')
    string_or_regexp = /#{string_or_regexp}/ if string_or_regexp.kind_of?(String)
    assert_match string_or_regexp,@output.string,desc
  end

  def refute_output_contained(string_or_regexp,desc='')
    string_or_regexp = /#{string_or_regexp}/ if string_or_regexp.kind_of?(String)
    refute_match string_or_regexp,@output.string,desc
  end

  def any_option
    ('a'..'z').to_a[@option_index].tap { @option_index += 1 }
  end

  def any_long_option
    ["foo","bar","blah"].sample
  end

  def any_desc
    [
      "This command does some stuff",
      "Do things and whatnot",
      "Behold the power of this command"
    ].sample
  end

  def any_command_name
    command_name = ["new","edit","delete","create","update"].sample
    while @command_names_used.include?(command_name)
      command_name = ["new","edit","delete","create","update"].sample
    end
    @command_names_used << command_name
    command_name
  end
end
