# frozen_string_literal: true

require "net/http"

namespace :templates do
  desc "Run tests for templates"
  task test: [ :daemonize, :npm, :rackup, :wait, :mocha, :kill, :exit ]
  task serve: [ :npm, :rackup ]

  workdir = Pathname(EXPANDED_CWD).join("test/templates")
  pid     = Pathname(Dir.tmpdir).join("web_console_test.pid")
  runner  = URI.parse("http://#{ENV['IP'] || '127.0.0.1'}:#{ENV['PORT'] || 29292}/html/test_runner.html")
  rackup  = "rackup --host #{runner.host} --port #{runner.port}"
  result  = nil

  def need_to_wait?(uri)
    Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.path) }
  rescue Errno::ECONNREFUSED
    retry if yield
  end

  task :daemonize do
    rackup += " -D --pid #{pid}"
  end

  task :npm do
    Dir.chdir(workdir) { system "npm install --silent" }
  end

  task :rackup do
    Dir.chdir(workdir) { system rackup }
  end

  task :wait do
    cnt = 0
    need_to_wait?(runner) { sleep 1; cnt += 1; cnt < 5 }
  end

  task :mocha do
    Dir.chdir(workdir) { result = system("npx mocha-headless-chrome -f #{runner} -r dot") }
  end

  task :kill do
    system "kill #{File.read pid}"
  end

  task :exit do
    exit result
  end
end
