require_relative "test_helper"
require_relative "support/fake_std_out"

class GLITest < Minitest::Test
  include TestHelper

  def setup
    @fake_stdout = FakeStdOut.new
    @fake_stderr = FakeStdOut.new
    @original_stdout = $stdout
    $stdout = @fake_stdout
    @original_stderr = $stderr
    $stderr = @fake_stderr
    @app = CLIApp.new

    @config_file = File.expand_path(File.dirname(File.realpath(__FILE__)) + '/support/new_config.yml')
    @gli_debug = ENV['GLI_DEBUG']
    @app.error_device=@fake_stderr
    ENV.delete('GLI_DEBUG')
  end

  def teardown
    File.delete(@config_file) if File.exist?(@config_file)
    ENV['GLI_DEBUG'] = @gli_debug
    @app.error_device=$stderr
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  def test_flag_create
    @app.reset
    do_test_flag_create(@app)
    do_test_flag_create(GLI::Command.new(:names => :f))
  end

  def test_create_commands_using_strings
    @app.reset
    @app.flag ['f','flag']
    @app.switch ['s','some-switch']
    @app.command 'command','command-with-dash' do |c|
    end
    assert @app.commands.include? :command
    assert @app.flags.include? :f
    assert @app.switches.include? :s
    assert @app.commands[:command].aliases.include? :'command-with-dash'
    assert @app.flags[:f].aliases.include? :flag
    assert @app.switches[:s].aliases.include? :'some-switch'
  end

  def test_default_command
    @app.reset
    @called = false
    @app.command :foo do |c|
      c.action do |global, options, arguments|
        @called = true
      end
    end
    @app.default_command(:foo)
    assert_equal 0, @app.run([]), "Expected exit status to be 0"
    assert @called, "Expected default command to be executed"
  end

  def test_command_options_can_be_required
    @app.reset
    @called = false
    @app.command :foo do |c|
      c.flag :flag, :required => true
      c.flag :other_flag, :required => true
      c.action do |global, options, arguments|
        @called = true
      end
    end
    assert_equal 64, @app.run(['foo']), "Expected exit status to be 64"
    assert  @fake_stderr.contained?(/requires these options.*flag/), @fake_stderr.strings.inspect
    assert  @fake_stderr.contained?(/requires these options.*other_flag/), @fake_stderr.strings.inspect
    assert !@called

    assert_equal 0, @app.run(['foo','--flag=bar','--other_flag=blah']), "Expected exit status to be 0 #{@fake_stderr.strings.join(',')}"
    assert @called

  end

  def test_command_options_accepting_multiple_values_can_be_required
    @app.reset
    @called = false
    @app.command :foo do |c|
      c.flag :flag, :required => true, :multiple => true
      c.action do |global, options, arguments|
        @called = true
      end
    end
    assert_equal 64, @app.run(['foo']), "Expected exit status to be 64"
    assert  @fake_stderr.contained?(/requires these options.*flag/), @fake_stderr.strings.inspect
    assert !@called

    assert_equal 0, @app.run(['foo','--flag=bar']), "Expected exit status to be 0 #{@fake_stderr.strings.join(',')}"
    assert @called

  end

  def test_global_options_can_be_required
    @app.reset
    @called = false
    @app.flag :flag, :required => true
    @app.flag :other_flag, :required => true
    @app.command :foo do |c|
      c.action do |global, options, arguments|
        @called = true
      end
    end
    assert_equal 64, @app.run(['foo']), "Expected exit status to be 64"
    assert  @fake_stderr.contained?(/requires these options.*flag/), @fake_stderr.strings.inspect
    assert  @fake_stderr.contained?(/requires these options.*other_flag/), @fake_stderr.strings.inspect
    assert !@called

    assert_equal 0, @app.run(['--flag=bar','--other_flag=blah','foo']), "Expected exit status to be 0 #{@fake_stderr.strings.join(',')}"
    assert @called

  end

  def test_global_options_accepting_multiple_can_be_required
    @app.reset
    @called = false
    @app.flag :flag, :required => true, :multiple => true
    @app.command :foo do |c|
      c.action do |global, options, arguments|
        @called = true
      end
    end
    assert_equal 64, @app.run(['foo']), "Expected exit status to be 64"
    assert  @fake_stderr.contained?(/requires these options.*flag/), @fake_stderr.strings.inspect
    assert !@called

    assert_equal 0, @app.run(['--flag=bar','foo']), "Expected exit status to be 0 #{@fake_stderr.strings.join(',')}"
    assert @called

  end

  def test_global_required_options_are_ignored_on_help
    @app.reset
    @called = false
    @app.flag :flag, :required => true
    @app.flag :other_flag, :required => true
    @app.command :foo do |c|
      c.action do |global, options, arguments|
        @called = true
      end
    end
    assert_equal 0, @app.run(['help']), "Expected exit status to be 64"
    assert  !@fake_stderr.contained?(/flag is required/), @fake_stderr.strings.inspect
    assert  !@fake_stderr.contained?(/other_flag is required/), @fake_stderr.strings.inspect
  end

  def test_flag_with_space_barfs
    @app.reset
    assert_raises(ArgumentError) { @app.flag ['some flag'] }
    assert_raises(ArgumentError) { @app.flag ['f','some flag'] }
    assert_raises(ArgumentError) { @app.switch ['some switch'] }
    assert_raises(ArgumentError) { @app.switch ['f','some switch'] }
    assert_raises(ArgumentError) { @app.command ['some command'] }
    assert_raises(ArgumentError) { @app.command ['f','some command'] }
  end

  def test_init_from_config
    failure = nil
    @app.reset
    @app.config_file(File.expand_path(File.dirname(File.realpath(__FILE__)) + '/support/gli_test_config.yml'))
    @app.flag :f
    @app.switch :s
    @app.flag :g
    @app.default_value true
    @app.switch :t
    called = false
    @app.command :command do |c|
      c.flag :f
      c.switch :s
      c.flag :g
      c.action do |g,o,a|
        begin
          called = true
          assert_equal "foo",g[:f]
          assert_equal "bar",o[:g]
          assert !g[:g]
          assert !o[:f]
          assert !g[:s]
          assert o[:s]
          assert !g[:t]
        rescue Exception => ex
          failure = ex
        end
      end
    end
    @app.run(['command'])
    assert called
    raise failure if !failure.nil?
  end


  def test_command_line_overrides_config
    failure = nil
    @app.reset
    @app.config_file(File.expand_path(File.dirname(File.realpath(__FILE__)) + '/support/gli_test_config.yml'))
    @app.flag :f
    @app.switch :s
    @app.flag :g
    @app.switch :bleorgh
    called = false
    @app.command :command do |c|
      c.flag :f
      c.switch :s
      c.flag :g
      c.action do |g,o,a|
        begin
          called = true
          assert_equal "baaz",o[:g]
          assert_equal "bar",g[:f]
          assert !g[:g],o.inspect
          assert !o[:f],o.inspect
          assert !g[:s],o.inspect
          assert o[:s],o.inspect
          assert g[:bleorgh] != nil,"Expected :bleorgh to have a value"
          assert g[:bleorgh] == false,"Expected :bleorgh to be false"
        rescue Exception => ex
          failure = ex
        end
      end
    end
    assert_equal 0,@app.run(%w(-f bar --no-bleorgh command -g baaz)),@fake_stderr.to_s
    assert called
    raise failure if !failure.nil?
  end

  def test_no_overwrite_config
    config_file = File.expand_path(File.dirname(File.realpath(__FILE__)) + '/support/gli_test_config.yml')
    config_file_contents = File.read(config_file)
    @app.reset
    @app.config_file(config_file)
    assert_equal 1,@app.run(['initconfig'])
    assert @fake_stderr.strings.grep(/--force/),@fake_stderr.strings.inspect
    assert !@fake_stdout.contained?(/written/), @fake_stdout.strings.inspect
    config_file_contents_after = File.read(config_file)
    assert_equal(config_file_contents,config_file_contents_after)
  end

  def test_config_file_name
    @app.reset
    file = @app.config_file("foo")
    assert_equal(Etc.getpwuid.dir + "/foo",file)
    file = @app.config_file("/foo")
    assert_equal "/foo",file
    init_command = @app.commands[:initconfig]
    assert init_command
  end

  def test_initconfig_command
    @app.reset
    @app.config_file(@config_file)
    @app.flag :f
    @app.switch :s, :salias
    @app.switch :w
    @app.flag :bigflag, :bigalias
    @app.flag :biggestflag
    @app.command :foo do |c|
    end
    @app.command :bar do |c|
    end
    @app.command :blah do |c|
    end
    @app.on_error do |ex|
      raise ex
    end
    @app.run(['-f','foo','-s','--bigflag=bleorgh','initconfig'])
    assert @fake_stdout.contained?(/written/), @fake_stdout.strings.inspect

    written_config = File.open(@config_file) { |f| YAML::load(f) }

    assert_equal 'foo',written_config[:f]
    assert_equal 'bleorgh',written_config[:bigflag]
    assert !written_config[:bigalias]
    assert written_config[:s]
    assert !written_config[:salias]
    assert !written_config[:w]
    assert_nil written_config[:biggestflag]
    assert written_config[GLI::InitConfig::COMMANDS_KEY]
    assert written_config[GLI::InitConfig::COMMANDS_KEY][:foo]
    assert written_config[GLI::InitConfig::COMMANDS_KEY][:bar]
    assert written_config[GLI::InitConfig::COMMANDS_KEY][:blah]

  end

  def test_initconfig_permissions
    @app.reset
    @app.config_file(@config_file)
    @app.run(['initconfig'])
    oct_mode = "%o" % File.stat(@config_file).mode
    assert_match /0600$/, oct_mode
  end

  def do_test_flag_create(object)
    description = 'this is a description'
    long_desc = 'this is a very long description'
    object.desc description
    object.long_desc long_desc
    object.arg_name 'filename'
    object.default_value '~/.blah.rc'
    object.flag :f
    assert (object.flags[:f] )
    assert_equal(description,object.flags[:f].description)
    assert_equal(long_desc,object.flags[:f].long_description)
    assert(nil != object.flags[:f].usage)
    assert(object.usage != nil) if object.respond_to? :usage;
  end

  def test_switch_create
    @app.reset
    do_test_switch_create(@app)
    do_test_switch_create(GLI::Command.new(:names => :f))
  end

  def test_switch_create_twice
    @app.reset
    do_test_switch_create_twice(@app)
    do_test_switch_create_twice(GLI::Command.new(:names => :f))
  end

  def test_all_aliases_in_options
    @app.reset
    @app.on_error { |ex| raise ex }
    @app.flag [:f,:flag,:'big-flag-name']
    @app.switch [:s,:switch,:'big-switch-name']
    @app.command [:com,:command] do |c|
      c.flag [:g,:gflag]
      c.switch [:h,:hswitch]
      c.action do |global,options,args|
        assert_equal 'foo',global[:f]
        assert_equal global[:f],global[:flag]
        assert_equal global[:f],global['f']
        assert_equal global[:f],global['flag']
        assert_equal global[:f],global['big-flag-name']
        assert_equal global[:f],global[:'big-flag-name']

        assert global[:s]
        assert global[:switch]
        assert global[:'big-switch-name']
        assert global['s']
        assert global['switch']
        assert global['big-switch-name']

        assert_equal 'bar',options[:g]
        assert_equal options[:g],options['g']
        assert_equal options[:g],options['gflag']
        assert_equal options[:g],options[:gflag]

        assert options[:h]
        assert options['h']
        assert options[:hswitch]
        assert options['hswitch']
      end
    end
    @app.run(%w(-f foo -s command -g bar -h some_arg))
  end

  def test_use_hash_by_default
    @app.reset
    @app.switch :g
    @app.command :command do |c|
      c.switch :f
      c.action do |global,options,args|
        assert_equal Hash,global.class
        assert_equal Hash,options.class
      end
    end
    @app.run(%w(-g command -f))
  end

  def test_flag_array_of_options_global
    @app.reset
    @app.flag :foo, :must_match => ['bar','blah','baz']
    @app.command :command do |c|
      c.action do
      end
    end
    assert_equal 64,@app.run(%w(--foo=cruddo command)),@fake_stderr.to_s
    assert @fake_stderr.contained?(/error: invalid argument: --foo=cruddo/),"STDERR was:\n" + @fake_stderr.to_s
    assert_equal 0,@app.run(%w(--foo=blah command)),@fake_stderr.to_s
  end

  def test_flag_hash_of_options_global
    @app.reset
    @app.flag :foo, :must_match => { 'bar' => "BAR", 'blah' => "BLAH" }
    @foo_arg_value = nil
    @app.command :command do |c|
      c.action do |g,o,a|
        @foo_arg_value = g[:foo]
      end
    end
    assert_equal 64,@app.run(%w(--foo=cruddo command)),@fake_stderr.to_s
    assert @fake_stderr.contained?(/error: invalid argument: --foo=cruddo/),"STDERR was:\n" + @fake_stderr.to_s
    assert_equal 0,@app.run(%w(--foo=blah command)),@fake_stderr.to_s
    assert_equal 'BLAH',@foo_arg_value
  end

  def test_flag_regexp_global
    @app.reset
    @app.flag :foo, :must_match => /bar/
    @app.command :command do |c|
      c.action do
      end
    end
    assert_equal 64,@app.run(%w(--foo=cruddo command)),@fake_stderr.to_s
    assert @fake_stderr.contained?(/error: invalid argument: --foo=cruddo/),"STDERR was:\n" + @fake_stderr.to_s
  end

  def test_flag_regexp_global_short_form
    @app.reset
    @app.flag :f, :must_match => /bar/
    @app.command :command do |c|
      c.action do
      end
    end
    assert_equal 64,@app.run(%w(-f cruddo command)),@fake_stderr.to_s
    assert @fake_stderr.contained?(/error: invalid argument: -f cruddo/),"STDERR was:\n" + @fake_stderr.to_s
  end

  def test_flag_regexp_command
    @app.reset
    @app.command :command do |c|
      c.flag :foo, :must_match => /bar/
      c.action do
      end
    end
    assert_equal 64,@app.run(%w(command --foo=cruddo)),@fake_stderr.to_s
    assert @fake_stderr.contained?(/error: invalid argument: --foo=cruddo/),"STDERR was:\n" + @fake_stderr.to_s
  end

  def test_use_openstruct
    @app.reset
    @app.switch :g
    @app.use_openstruct true
    @app.command :command do |c|
      c.switch :f
      c.action do |global,options,args|
        assert_equal GLI::Options,global.class
        assert_equal GLI::Options,options.class
      end
    end
    @app.run(%w(-g command -f))
  end

  def test_repeated_option_names
    @app.reset
    @app.on_error { |ex| raise ex }
    @app.flag [:f,:flag]
    assert_raises(ArgumentError) { @app.switch [:foo,:flag] }
    assert_raises(ArgumentError) { @app.switch [:f] }

    @app.switch [:x,:y]
    assert_raises(ArgumentError) { @app.flag [:x] }
    assert_raises(ArgumentError) { @app.flag [:y] }

    # This shouldn't raise; :help is special
    @app.switch :help
  end

  def test_repeated_option_names_on_command
    @app.reset
    @app.on_error { |ex| raise ex }
    @app.command :command do |c|
      c.flag [:f,:flag]
      assert_raises(ArgumentError) { c.switch [:foo,:flag] }
      assert_raises(ArgumentError) { c.switch [:f] }
      assert_raises(ArgumentError) { c.flag [:foo,:flag] }
      assert_raises(ArgumentError) { c.flag [:f] }
    end
    @app.command :command3 do |c|
      c.switch [:s,:switch]
      assert_raises(ArgumentError) { c.switch [:switch] }
      assert_raises(ArgumentError) { c.switch [:s] }
      assert_raises(ArgumentError) { c.flag [:switch] }
      assert_raises(ArgumentError) { c.flag [:s] }
    end
  end

  def test_two_flags
    @app.reset
    @app.on_error do |ex|
      raise ex
    end
    @app.command [:foo] do |c|
      c.flag :i
      c.flag :s
      c.action do |g,o,a|
        assert_equal "5", o[:i]
        assert_equal "a", o[:s]
      end
    end
    @app.run(['foo', '-i','5','-s','a'])
  end

  def test_two_flags_with_a_default
    @app.reset
    @app.on_error do |ex|
      raise ex
    end
    @app.command [:foo] do |c|
      c.default_value "1"
      c.flag :i
      c.flag :s
      c.action do |g,o,a|
        assert_equal "1", o[:i]
        assert_equal nil, o[:s]
      end
    end
    @app.run(['foo','a'])
  end

  def test_switch_with_default_of_true
    @app.reset
    @app.on_error do |ex|
      raise ex
    end
    @switch_value = nil

    @app.command [:foo] do |c|
      c.default_value true
      c.switch :switch
      c.action do |g,o,a|
        @switch_value = o[:switch]
      end
    end
    @app.run(['foo'])

    assert @switch_value == true,"Got: '#{@switch_value}', but expected true"

    @app.run(['foo','--no-switch'])

    assert @switch_value == false,"Got: '#{@switch_value}', but expected false"
  end

  def test_switch_with_default_true_and_not_negatable_causes_exception
    @app.reset
    @app.on_error do |ex|
      raise ex
    end
    @switch_value = nil

    assert_raises(RuntimeError) do
      @app.command [:foo] do |c|
        c.switch :switch, :default_value => true, :negatable => false
      end
    end
  end

  def test_two_flags_using_equals_with_a_default
    @app.reset
    @app.on_error do |ex|
      raise ex
    end
    @app.command [:foo] do |c|
      c.default_value "1"
      c.flag :i
      c.flag :s
      c.action do |g,o,a|
        assert_equal "5", o[:i],o.inspect
        assert_equal "a", o[:s],o.inspect
      end
    end
    @app.run(['foo', '-i5','-sa'])
  end

  def test_default_values_are_available_on_all_aliases
    @app.reset
    @app.on_error { |e| raise e }

    @app.default_value "global_default"
    @app.flag [ :f, :flag ]

    @global_options = {}
    @command_options = {}

    @app.command [:foo] do |c|
      c.default_value "command_default"
      c.flag [ :c,:commandflag]

      c.action do |g,o,a|
        @global_options = g
        @command_options = o
      end
    end

    @app.run(["foo"])

    assert_equal "global_default", @global_options[:f]
    assert_equal "global_default", @global_options[:flag]
    assert_equal "global_default", @global_options["f"]
    assert_equal "global_default", @global_options["flag"]

    assert_equal "command_default", @command_options[:c]
    assert_equal "command_default", @command_options[:commandflag]
    assert_equal "command_default", @command_options["c"]
    assert_equal "command_default", @command_options["commandflag"]
  end

  def test_exits_zero_on_success
    @app.reset
    assert_equal 0,@app.run([]),@fake_stderr.to_s
  end

  def test_exits_nonzero_on_bad_command_line
    @app.reset
    @app.on_error { true }
    assert_equal 64,@app.run(['asdfasdfasdf'])
  end

  def test_exists_nonzero_on_raise_from_command
    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        raise "Problem"
      end
    end
    assert_equal 1,@app.run(['foo'])
  end

  def test_exits_nonzero_with_custom_exception
    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        raise GLI::CustomExit.new("Problem",45)
      end
    end
    assert_equal 45,@app.run(['foo'])
  end

  def test_exits_nonzero_with_exit_method
    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        @app.exit_now!("Problem",45)
      end
    end
    assert_equal 45,@app.run(['foo'])
  end

  def test_exits_nonzero_with_exit_method_by_default
    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        @app.exit_now!("Problem")
      end
    end
    assert_equal 1,@app.run(['foo'])
  end

  def test_help_now_exits_and_shows_help
    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        @app.help_now!("Problem")
      end
    end
    assert_equal 64,@app.run(['foo']),@fake_stderr.strings.join("\n")
  end

  def test_custom_exception_causes_error_to_be_printed_to_stderr
    @app.reset
    @app.on_error { true }
    error_message = "Something went wrong"
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        raise error_message
      end
    end
    @app.run(['foo'])
    assert @fake_stderr.strings.include?("error: #{error_message}"),"STDERR was:\n" + @fake_stderr.to_s
  end

  def test_gli_debug_overrides_error_hiding
    ENV['GLI_DEBUG'] = 'true'

    @app.reset
    @app.on_error { true }
    @app.command(:foo) do |c|
      c.action do |g,o,a|
        @app.exit_now!("Problem",45)
      end
    end

    assert_raises(GLI::CustomExit) { @app.run(['foo']) }
  end

  def test_gli_help_does_not_raise_on_debug
    ENV['GLI_DEBUG'] = 'true'

    @app.reset
    @app.command(:multiply) do |c|
      c.action do |g,o,a|
        # Nothing
      end
    end

    begin
      @app.run(['multiply', '--help'])
    rescue GLI::CustomExit
      assert false, "Expected no exception"
    end
  end

  class ConvertMe
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end

  def test_that_we_can_add_new_casts_for_flags
    @app.reset
    @app.accept(ConvertMe) do |value|
      ConvertMe.new(value)
    end
    @app.flag :foo, :type => ConvertMe

    @foo = nil
    @baz = nil

    @app.command(:bar) do |c|
      c.flag :baz, :type => ConvertMe
      c.action do |g,o,a|
        @foo = g[:foo]
        @baz = o[:baz]
      end
    end

    assert_equal 0,@app.run(['--foo','blah','bar','--baz=crud']),@fake_stderr.to_s

    assert @foo.kind_of?(ConvertMe),"Expected a ConvertMe, but get a #{@foo.class}"
    assert_equal 'blah',@foo.value

    assert @baz.kind_of?(ConvertMe),"Expected a ConvertMe, but get a #{@foo.class}"
    assert_equal 'crud',@baz.value
  end

  def test_that_flags_can_be_used_multiple_times
    @app.reset
    @app.flag :flag, :multiple => true
    @app.command :foo do |c|
      c.action do |options, _, _|
        @flag = options[:flag]
      end
    end

    assert_equal 0,@app.run(%w(--flag 1 --flag=2 --flag 3 foo)),@fake_stderr.to_s

    assert_equal ['1','2','3'],@flag
  end

  def test_that_multiple_use_flags_are_empty_arrays_by_default
    @app.reset
    @app.flag :flag, :multiple => true
    @app.command :foo do |c|
      c.action do |options, _, _|
        @flag = options[:flag]
      end
    end

    assert_equal 0,@app.run(['foo']),@fake_stderr.to_s

    assert_equal [],@flag
  end

  def test_that_multiple_use_flags_can_take_other_defaults
    @app.reset
    @app.flag :flag, :multiple => true, :default_value => ['1']
    @app.command :foo do |c|
      c.action do |options, _, _|
        @flag = options[:flag]
      end
    end

    assert_equal 0,@app.run(['foo']),@fake_stderr.to_s

    assert_equal ['1'],@flag
  end

  def test_that_we_mutate_ARGV_by_default
    @app.reset
    @app.flag :f
    @app.command :foo do |c|
      c.action do |*args|
      end
    end

    argv = %w(-f some_flag foo bar blah)

    @app.run(argv)

    assert_equal %w(bar blah),argv
  end

  def test_that_we_can_avoid_mutating_ARGV
    @app.reset
    @app.flag :f
    @app.command :foo do |c|
      c.action do |*args|
      end
    end
    @app.preserve_argv

    argv = %w(-f some_flag foo bar blah)

    @app.run(argv)

    assert_equal %w(-f some_flag foo bar blah),argv
  end

  def test_missing_command
    @called = false
    @app.command_missing do |command_name, global_options|
      @app.command command_name do |c|
        c.action do
          @called = true
        end
      end
    end

    assert_equal 0, @app.run(['foobar']),"Expected exit status to be 0"
    assert @called,"Expected missing command to be called"
  end

  def test_missing_command_not_handled
    @app.command_missing do |command_name, global_options|
      # do nothing, i.e. don't handle the command
    end

    assert_equal 64,@app.run(['foobar']),"Expected exit status to be 64"
  end

  def test_missing_command_returns_non_command_object
    @app.command_missing do |command_name, global_options|
      true
    end

    assert_equal 64,@app.run(['foobar']),"Expected exit status to be 64"
  end

  private

  def do_test_flag_create(object)
    description = 'this is a description'
    long_desc = 'this is a very long description'
    object.desc description
    object.long_desc long_desc
    object.arg_name 'filename'
    object.default_value '~/.blah.rc'
    object.flag :f
    assert (object.flags[:f] )
    assert_equal(description,object.flags[:f].description)
    assert_equal(long_desc,object.flags[:f].long_description)
  end

  def do_test_switch_create(object)
    do_test_switch_create_classic(object)
    do_test_switch_create_compact(object)
  end

  def do_test_switch_create_classic(object)
    @description = 'this is a description'
    @long_description = 'this is a very long description'
    object.desc @description
    object.long_desc @long_description
    object.switch :f
    assert object.switches[:f]
    assert_equal @description,object.switches[:f].description,"For switch #{:f}"
    assert_equal @long_description,object.switches[:f].long_description,"For switch #{:f}"
    assert(object.usage != nil) if object.respond_to? :usage
  end

  def do_test_switch_create_compact(object)
    @description = 'this is a description'
    @long_description = 'this is a very long description'
    object.switch :g, :desc => @description, :long_desc => @long_description
    assert object.switches[:g]
    assert_equal @description,object.switches[:g].description,"For switch #{:g}"
    assert_equal @long_description,object.switches[:g].long_description,"For switch #{:g}"
    assert(object.usage != nil) if object.respond_to? :usage
  end

  def do_test_switch_create_twice(object)
    description = 'this is a description'
    object.desc description
    object.switch :f
    assert (object.switches[:f] )
    assert_equal(description,object.switches[:f].description)
    object.switch :g
    assert (object.switches[:g])
    assert_equal(nil,object.switches[:g].description)
    assert(object.usage != nil) if object.respond_to? :usage
  end


end
