# it throws following message:
# W, [2018-02-06T18:16:06.360071 #72025]  WARN -- :       This usage of the Code Climate Test Reporter is now deprecated. Since version
#       1.0, we now require you to run `SimpleCov` in your test/spec helper, and then
#       run the provided `codeclimate-test-reporter` binary separately to report your
#       results to Code Climate.
#
#       More information here: https://github.com/codeclimate/ruby-test-reporter/blob/master/README.md
# require "codeclimate-test-reporter"
# CodeClimate::TestReporter.start

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "rspec"
require "timecop"
require "pp"
require "fakefs/safe"
require "fakefs/spec_helpers"

$:.unshift File.expand_path("../../lib", __FILE__)

def mock_export_error(message)
  expect { yield }.to raise_error(Foreman::Export::Exception, message)
end

def mock_error(subject, message)
  mock_exit do
    expect(subject).to receive(:puts).with("ERROR: #{message}")
    yield
  end
end

def make_pipe
  IO.method(:pipe).arity.zero? ? IO.pipe : IO.pipe("BINARY")
end

def foreman(args)
  capture_stdout do
    begin
      Foreman::CLI.start(args.split(" "))
    rescue SystemExit
    end
  end
end

def forked_foreman(args)
  rd, wr = make_pipe
  Process.spawn("bundle exec bin/foreman #{args}", :out => wr, :err => wr)
  wr.close
  rd.read
end

def fork_and_capture(&blk)
  rd, wr = make_pipe
  pid = fork do
    rd.close
    wr.sync = true
    $stdout.reopen wr
    $stderr.reopen wr
    blk.call
    $stdout.flush
    $stdout.close
  end
  wr.close
  Process.wait pid
  buffer = ""
  until rd.eof?
    buffer += rd.gets
  end
end

def fork_and_get_exitstatus(args)
  pid = Process.spawn("bundle exec bin/foreman #{args}", :out => "/dev/null", :err => "/dev/null")
  Process.wait(pid)
  $?.exitstatus
end

def mock_exit(&block)
  expect(block).to raise_error(SystemExit)
end

def write_foreman_config(app)
  File.open("/etc/foreman/#{app}.conf", "w") do |file|
    file.puts %{#{app}_processes="alpha bravo"}
    file.puts %{#{app}_alpha="1"}
    file.puts %{#{app}_bravo="2"}
  end
end

def write_procfile(procfile="Procfile", alpha_env="")
  FileUtils.mkdir_p(File.dirname(procfile))
  File.open(procfile, "w") do |file|
    file.puts "alpha: ./alpha" + " #{alpha_env}".rstrip
    file.puts "\n"
    file.puts "bravo:\t./bravo"
    file.puts "foo_bar:\t./foo_bar"
    file.puts "foo-bar:\t./foo-bar"
    file.puts "# baz:\t./baz"
  end
  File.expand_path(procfile)
end

def write_file(file)
  FileUtils.mkdir_p(File.dirname(file))
  File.open(file, 'w') do |f|
    yield(f) if block_given?
  end
end

def write_env(env=".env", options={"FOO"=>"bar"})
  File.open(env, "w") do |file|
    options.each do |key, val|
      file.puts "#{key}=#{val}"
    end
  end
end

def without_fakefs
  FakeFS.deactivate!
  ret = yield
  FakeFS.activate!
  ret
end

def load_export_templates_into_fakefs(type)
  without_fakefs do
    Dir[File.expand_path("../../data/export/#{type}/**/*", __FILE__)].inject({}) do |hash, file|
      next(hash) if File.directory?(file)
      hash.update(file => File.read(file))
    end
  end.each do |filename, contents|
    FileUtils.mkdir_p File.dirname(filename)
    File.open(filename, "w") do |f|
      f.puts contents
    end
  end
end

def resource_path(filename)
  File.expand_path("../resources/#{filename}", __FILE__)
end

def example_export_file(filename)
  FakeFS.deactivate!
  data = File.read(File.expand_path(resource_path("export/#{filename}"), __FILE__))
  FakeFS.activate!
  data
end

def preserving_env
  old_env = ENV.to_hash
  begin
    yield
  ensure
    ENV.clear
    ENV.update(old_env)
  end
end

def normalize_space(s)
  s.gsub(/\n[\n\s]*/, "\n")
end

def capture_stdout
  old_stdout = $stdout.dup
  rd, wr = make_pipe
  $stdout = wr
  yield
  wr.close
  rd.read
ensure
  $stdout = old_stdout
end

RSpec.configure do |config|
  config.color = true
  config.order = 'rand'
  config.include FakeFS::SpecHelpers, :fakefs
  config.before(:each) do
    FileUtils.mkdir_p('/tmp')
  end
  config.after(:each) do
    FileUtils.rm_rf('/tmp')
  end
end
