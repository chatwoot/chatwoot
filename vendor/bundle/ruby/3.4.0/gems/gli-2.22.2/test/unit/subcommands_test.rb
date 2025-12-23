require_relative "test_helper"
require_relative "support/fake_std_out"

class SubcommandsTest < Minitest::Test
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
  end

  def teardown
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  def test_we_run_add_command_using_add
    we_have_a_command_with_two_subcommands
    run_app('remote',"add",'-f','foo','bar')
    assert_command_ran_with(:add, :command_options => {:f => true}, :args => %w(foo bar))
  end
  def test_we_run_add_command_using_new
    we_have_a_command_with_two_subcommands
    run_app('remote',"new",'-f','foo','bar')
    assert_command_ran_with(:add, :command_options => {:f => true}, :args => %w(foo bar))
  end

  def test_subcommands_not_used_on_command_line_uses_base_action
    we_have_a_command_with_two_subcommands
    run_app('remote','foo','bar')
    assert_command_ran_with(:base, :command_options => {:f => false}, :args => %w(foo bar))
  end

  def test_switches_and_flags_on_subcommand_available
    we_have_a_command_with_two_subcommands(:switches => [:addswitch], :flags => [:addflag])
    run_app('remote','add','--addswitch','--addflag','foo','bar')
    assert_command_ran_with(:add,:command_options => { :addswitch => true, :addflag => 'foo', :f => false },
                            :args => ['bar'])
  end

  def test_help_flag_works_in_normal_mode
    @app.subcommand_option_handling :normal
    we_have_a_command_with_two_subcommands
    @app.run(["remote", "add", "--help"]) rescue nil
    refute_match /^error/, @fake_stderr.to_s, "should not output an error message"
  end

  def test_help_flag_works_in_legacy_mode
    @app.subcommand_option_handling :legacy
    we_have_a_command_with_two_subcommands
    @app.run(["remote", "add", "--help"]) rescue nil
    refute_match /^error/, @fake_stderr.to_s, "should not output an error message"
  end

  def test_we_can_reopen_commands_to_add_new_subcommands
    @app.command :remote do |p|
      p.command :add do |c|
        c.action do |global_options,command_options,args|
          @ran_command = :add
        end
      end
    end
    @app.command :remote do |p|
      p.command :new do |c|
        c.action do |global_options,command_options,args|
          @ran_command = :new
        end
      end
    end
    run_app('remote','new')
    assert_equal(@ran_command, :new)
    run_app('remote', 'add')
    assert_equal(@ran_command, :add)
  end

  def test_reopening_commands_doesnt_readd_to_output
    @app.command :remote do |p|
      p.command(:add) { }
    end
    @app.command :remote do |p|
      p.command(:new) { }
    end
    command_names = @app.instance_variable_get("@commands_declaration_order").collect { |c| c.name }
    assert_equal 1, command_names.grep(:remote).size
  end


  def test_we_can_reopen_commands_without_causing_conflicts
    @app.command :remote do |p|
      p.command :add do |c|
        c.action do |global_options,command_options,args|
          @ran_command = :remote_add
        end
      end
    end
    @app.command :local do |p|
      p.command :add do |c|
        c.action do |global_options,command_options,args|
          @ran_command = :local_add
        end
      end
    end
    run_app('remote','add')
    assert_equal(@ran_command, :remote_add)
    run_app('local', 'add')
    assert_equal(@ran_command, :local_add)
  end


  def test_we_can_nest_subcommands_very_deep
    @run_results = { :add => nil, :rename => nil, :base => nil }
    @app.command :remote do |c|

      c.switch :f
      c.command :add do |add|
        add.command :some do |some|
          some.command :cmd do |cmd|
            cmd.switch :s
            cmd.action do |global_options,command_options,args|
              @run_results[:cmd] = [global_options,command_options,args]
            end
          end
        end
      end
    end
    ENV['GLI_DEBUG'] = 'true'
    run_app('remote','add','some','cmd','-s','blah')
    assert_command_ran_with(:cmd, :command_options => {:s => true, :f => false},:args => ['blah'])
  end

  def test_when_any_command_has_no_action_but_there_are_args_indicate_unknown_command
    a_very_deeply_nested_command_structure
    assert_raises GLI::UnknownCommand do
      When run_app('remote','add','some','foo')
    end
    assert_match /Unknown command 'foo'/,@fake_stderr.to_s
  end

  def test_when_any_command_has_no_action_but_there_are_no_args_indicate_subcommand_needed
    a_very_deeply_nested_command_structure
    assert_raises GLI::BadCommandLine do
      When run_app('remote','add','some')
    end
    assert_match /Command 'some' requires a subcommand/,@fake_stderr.to_s
  end

private

  def run_app(*args)
    @exit_code = @app.run(args)
  end

  def a_very_deeply_nested_command_structure
    @run_results = { :add => nil, :rename => nil, :base => nil }
    @app.command :remote do |c|

      c.switch :f
      c.command :add do |add|
        add.command :some do |some|
          some.command :cmd do |cmd|
            cmd.switch :s
            cmd.action do |global_options,command_options,args|
              @run_results[:cmd] = [global_options,command_options,args]
            end
          end
        end
      end
    end
    ENV['GLI_DEBUG'] = 'true'
  end

  # expected_command - name of command exepcted to have been run
  # options:
  #   - global_options => hash of expected options
  #   - command_options => hash of expected command options
  #   - args => array of expected args
  def assert_command_ran_with(expected_command,options)
    global_options = options[:global_options] || { :help => false }
    @run_results.each do |command,results|
      if command == expected_command
        assert_equal(indifferent_hash(global_options),results[0])
        assert_equal(indifferent_hash(options[:command_options]),results[1])
        assert_equal(options[:args],results[2])
      else
        assert_nil results
      end
    end
  end

  def indifferent_hash(possibly_nil_hash)
    return {} if possibly_nil_hash.nil?
    possibly_nil_hash.keys.each do |key|
      if key.kind_of? Symbol
        possibly_nil_hash[key.to_s] = possibly_nil_hash[key] unless possibly_nil_hash.has_key?(key.to_s)
      elsif key.kind_of? String
        possibly_nil_hash[key.to_sym] = possibly_nil_hash[key] unless possibly_nil_hash.has_key?(key.to_sym)
      end
    end
    possibly_nil_hash
  end

  # options - 
  #     :flags => flags to add to :add
  #     :switiches => switiches to add to :add
  def we_have_a_command_with_two_subcommands(options = {})
    @run_results = { :add => nil, :rename => nil, :base => nil }
    @app.command :remote do |c|

      c.switch :f

      c.desc "add a remote"
      c.command [:add,:new] do |add|

        Array(options[:flags]).each { |_| add.flag _ }
        Array(options[:switches]).each { |_| add.switch _ }
        add.action do |global_options,command_options,args|
          @run_results[:add] = [global_options,command_options,args]
        end
      end

      c.desc "rename a remote"
      c.command :rename do |rename|
        rename.action do |global_options,command_options,args|
          @run_results[:rename] = [global_options,command_options,args]
        end
      end

      c.action do |global_options,command_options,args|
        @run_results[:base] = [global_options,command_options,args]
      end
    end
    ENV['GLI_DEBUG'] = 'true'
  end
end
