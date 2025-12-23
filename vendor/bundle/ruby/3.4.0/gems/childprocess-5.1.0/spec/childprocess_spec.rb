# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)


describe ChildProcess do

  here = File.dirname(__FILE__)

  let(:gemspec) { eval(File.read "#{here}/../childprocess.gemspec") }

  it 'validates cleanly' do
    if Gem::VERSION >= "3.5.0"
      expect { gemspec.validate }.not_to output(/warn/i).to_stderr
    else
      require 'rubygems/mock_gem_ui'

      mock_ui = Gem::MockGemUi.new
      Gem::DefaultUserInteraction.use_ui(mock_ui) { gemspec.validate }

      expect(mock_ui.error).to_not match(/warn/i)
    end
  end

  it "returns self when started" do
    process = sleeping_ruby

    expect(process.start).to eq process
    expect(process).to be_alive
  end

  it "raises ChildProcess::LaunchError if the process can't be started" do
    expect { invalid_process.start }.to raise_error(ChildProcess::LaunchError)
  end

  it 'raises ArgumentError if given a non-string argument' do
    expect { ChildProcess.build(nil, "unlikelytoexist") }.to raise_error(ArgumentError)
    expect { ChildProcess.build("foo", 1) }.to raise_error(ArgumentError)
  end

  it "knows if the process crashed" do
    process = exit_with(1).start
    process.wait

    expect(process).to be_crashed
  end

  it "knows if the process didn't crash" do
    process = exit_with(0).start
    process.wait

    expect(process).to_not be_crashed
  end

  it "can wait for a process to finish" do
    process = exit_with(0).start
    return_value = process.wait

    expect(process).to_not be_alive
    expect(return_value).to eq 0
  end

  it 'ignores #wait if process already finished' do
    process = exit_with(0).start
    sleep 0.01 until process.exited?

    expect(process.wait).to eql 0
  end

  it "escalates if TERM is ignored" do
    process = ignored('TERM').start
    process.stop
    expect(process).to be_exited
  end

  it "accepts a timeout argument to #stop" do
    process = sleeping_ruby.start
    process.stop(exit_timeout)
  end

  it "lets child process inherit the environment of the current process" do
    Tempfile.open("env-spec") do |file|
      file.close
      with_env('INHERITED' => 'yes') do
        process = write_env(file.path).start
        process.wait
      end

      file.open
      child_env = eval rewind_and_read(file)
      expect(child_env['INHERITED']).to eql 'yes'
    end
  end

  it "can override env vars only for the child process" do
    Tempfile.open("env-spec") do |file|
      file.close
      process = write_env(file.path)
      process.environment['CHILD_ONLY'] = '1'
      process.start

      expect(ENV['CHILD_ONLY']).to be_nil

      process.wait

      file.open
      child_env = eval rewind_and_read(file)
      expect(child_env['CHILD_ONLY']).to eql '1'
    end
  end

  it 'allows unicode characters in the environment' do
    Tempfile.open("env-spec") do |file|
      file.close
      process = write_env(file.path)
      process.environment['FOö'] = 'baör'
      process.start
      process.wait

      file.open
      child_env = eval rewind_and_read(file)

      expect(child_env['FOö']).to eql 'baör'
    end
  end

  it "can set env vars using Symbol keys and values" do
    Tempfile.open("env-spec") do |file|
      process = ruby('puts ENV["SYMBOL_KEY"]')
      process.environment[:SYMBOL_KEY] = :VALUE
      process.io.stdout = file
      process.start
      process.wait
      expect(rewind_and_read(file)).to eq "VALUE\n"
    end
  end

  it "raises ChildProcess::InvalidEnvironmentVariable for invalid env vars" do
    process = ruby(':OK')
    process.environment["a\0b"] = '1'
    expect { process.start }.to raise_error(ChildProcess::InvalidEnvironmentVariable)

    process = ruby(':OK')
    process.environment["A=1"] = '2'
    expect { process.start }.to raise_error(ChildProcess::InvalidEnvironmentVariable)

    process = ruby(':OK')
    process.environment['A'] = "a\0b"
    expect { process.start }.to raise_error(ChildProcess::InvalidEnvironmentVariable)
  end

  it "inherits the parent's env vars also when some are overridden" do
    Tempfile.open("env-spec") do |file|
      file.close
      with_env('INHERITED' => 'yes', 'CHILD_ONLY' => 'no') do
        process = write_env(file.path)
        process.environment['CHILD_ONLY'] = 'yes'

        process.start
        process.wait

        file.open
        child_env = eval rewind_and_read(file)

        expect(child_env['INHERITED']).to eq 'yes'
        expect(child_env['CHILD_ONLY']).to eq 'yes'
      end
    end
  end

  it "can unset env vars" do
    Tempfile.open("env-spec") do |file|
      file.close
      ENV['CHILDPROCESS_UNSET'] = '1'
      process = write_env(file.path)
      process.environment['CHILDPROCESS_UNSET'] = nil
      process.start

      process.wait

      file.open
      child_env = eval rewind_and_read(file)
      expect(child_env).to_not have_key('CHILDPROCESS_UNSET')
    end
  end

  it 'does not see env vars unset in parent' do
    Tempfile.open('env-spec') do |file|
      file.close
      ENV['CHILDPROCESS_UNSET'] = nil
      process = write_env(file.path)
      process.start

      process.wait

      file.open
      child_env = eval rewind_and_read(file)
      expect(child_env).to_not have_key('CHILDPROCESS_UNSET')
    end
  end


  it "passes arguments to the child" do
    args = ["foo", "bar"]

    Tempfile.open("argv-spec") do |file|
      process = write_argv(file.path, *args).start
      process.wait

      expect(rewind_and_read(file)).to eql args.inspect
    end
  end

  it "lets a detached child live on" do
    p_pid = nil
    c_pid = nil

    Tempfile.open('grandparent_out') do |gp_file|
      # Create a parent and detached child process that will spit out their PID. Make sure that the child process lasts longer than the parent.
      p_process = ruby("$: << 'lib'; require 'childprocess' ; c_process = ChildProcess.build('ruby', '-e', 'puts \\\"Child PID: \#{Process.pid}\\\" ; sleep 5') ; c_process.io.inherit! ; c_process.detach = true ;  c_process.start ; puts \"Child PID: \#{c_process.pid}\" ; puts \"Parent PID: \#{Process.pid}\"")
      p_process.io.stdout = p_process.io.stderr = gp_file

      # Let the parent process die
      p_process.start
      p_process.wait


      # Gather parent and child PIDs
      pids = rewind_and_read(gp_file).split("\n")
      pids.collect! { |pid| pid[/\d+/].to_i }
      c_pid, p_pid = pids
    end

    # Check that the parent process has dies but the child process is still alive
    expect(alive?(p_pid)).to_not be true
    expect(alive?(c_pid)).to be true
  end

  it "preserves Dir.pwd in the child" do
    Tempfile.open("dir-spec-out") do |file|
      process = ruby("print Dir.pwd")
      process.io.stdout = process.io.stderr = file

      expected_dir = nil
      Dir.chdir(Dir.tmpdir) do
        expected_dir = Dir.pwd
        process.start
      end

      process.wait

      expect(rewind_and_read(file)).to eq expected_dir
    end
  end

  it "can handle whitespace, special characters and quotes in arguments" do
    args = ["foo bar", 'foo\bar', "'i-am-quoted'", '"i am double quoted"']

    Tempfile.open("argv-spec") do |file|
      process = write_argv(file.path, *args).start
      process.wait

      expect(rewind_and_read(file)).to eq args.inspect
    end
  end

  it 'handles whitespace in the executable name' do
    path = File.expand_path('foo bar')

    with_executable_at(path) do |proc|
      expect(proc.start).to eq proc
      expect(proc).to be_alive
    end
  end

  it "times out when polling for exit" do
    process = sleeping_ruby.start
    expect { process.poll_for_exit(0.1) }.to raise_error(ChildProcess::TimeoutError)
  end

  it "can change working directory" do
    process = ruby "print Dir.pwd"

    with_tmpdir { |dir|
      process.cwd = dir

      orig_pwd = Dir.pwd

      Tempfile.open('cwd') do |file|
        process.io.stdout = file

        process.start
        process.wait

        expect(rewind_and_read(file)).to eq dir
      end

      expect(Dir.pwd).to eq orig_pwd
    }
  end

  it 'kills the full process tree' do
    Tempfile.open('kill-process-tree') do |file|
      process = write_pid_in_sleepy_grand_child(file.path)
      process.leader = true
      process.start

      pid = wait_until(30) do
        Integer(rewind_and_read(file)) rescue nil
      end

      process.stop
      expect(process).to be_exited

      wait_until(3) { expect(alive?(pid)).to eql(false) }
    end
  end

  it 'releases the GIL while waiting for the process' do
    time = Time.now
    threads = []

    threads << Thread.new { sleeping_ruby(1).start.wait }
    threads << Thread.new(time) { expect(Time.now - time).to be < 0.5 }

    threads.each { |t| t.join }
  end

  it 'can check if a detached child is alive' do
    proc = ruby_process("-e", "sleep")
    proc.detach = true

    proc.start

    expect(proc).to be_alive
    proc.stop(0)

    expect(proc).to be_exited
  end

  describe 'OS detection' do

    before(:all) do
      # Save off original OS so that it can be restored later
      @original_host_os = RbConfig::CONFIG['host_os']
    end

    after(:each) do
      # Restore things to the real OS instead of the fake test OS
      RbConfig::CONFIG['host_os'] = @original_host_os
      ChildProcess.instance_variable_set(:@os, nil)
    end


    # TODO: add tests for other OSs
    context 'on a BSD system' do

      let(:bsd_patterns) { ['bsd', 'dragonfly'] }

      it 'correctly identifies BSD systems' do
        bsd_patterns.each do |pattern|
          RbConfig::CONFIG['host_os'] = pattern
          ChildProcess.instance_variable_set(:@os, nil)

          expect(ChildProcess.os).to eq(:bsd)
        end
      end

    end

  end

  it 'has a logger' do
    expect(ChildProcess).to respond_to(:logger)
  end

  it 'can change its logger' do
    expect(ChildProcess).to respond_to(:logger=)

    original_logger = ChildProcess.logger
    begin
      ChildProcess.logger = :some_other_logger
      expect(ChildProcess.logger).to eq(:some_other_logger)
    ensure
      ChildProcess.logger = original_logger
    end
  end


  describe 'logger' do

    before(:each) do
      ChildProcess.logger = logger
    end

    after(:all) do
      ChildProcess.logger = nil
    end


    context 'with the default logger' do

      let(:logger) { nil }


      it 'logs at INFO level by default' do
        expect(ChildProcess.logger.level).to eq(Logger::INFO)
      end

      it 'logs at DEBUG level by default if $DEBUG is on' do
        original_debug = $DEBUG

        begin
          $DEBUG = true

          expect(ChildProcess.logger.level).to eq(Logger::DEBUG)
        ensure
          $DEBUG = original_debug
        end
      end

      it "logs to stderr by default" do
        cap = capture_std { generate_log_messages }

        expect(cap.stdout).to be_empty
        expect(cap.stderr).to_not be_empty
      end

    end

    context 'with a custom logger' do

      let(:logger) { Logger.new($stdout) }

      it "logs to configured logger" do
        cap = capture_std { generate_log_messages }

        expect(cap.stdout).to_not be_empty
        expect(cap.stderr).to be_empty
      end

    end

  end

  describe '#started?' do
    subject { process.started? }

    context 'when not started' do
      let(:process) { sleeping_ruby(1) }

      it { is_expected.to be false }
    end

    context 'when started' do
      let(:process) { sleeping_ruby(1).start }

      it { is_expected.to be true }
    end

    context 'when finished' do
      before(:each) { process.wait }

      let(:process) { sleeping_ruby(0).start }

      it { is_expected.to be true }
    end

  end

end
