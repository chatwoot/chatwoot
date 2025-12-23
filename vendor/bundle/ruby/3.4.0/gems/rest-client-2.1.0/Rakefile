# load `rake build/install/release tasks'
require 'bundler/setup'
require_relative './lib/restclient/version'

namespace :ruby do
  Bundler::GemHelper.install_tasks(:name => 'rest-client')
end

require "rspec/core/rake_task"

desc "Run all specs"
RSpec::Core::RakeTask.new('spec')

desc "Run unit specs"
RSpec::Core::RakeTask.new('spec:unit') do |t|
  t.pattern = 'spec/unit/*_spec.rb'
end

desc "Run integration specs"
RSpec::Core::RakeTask.new('spec:integration') do |t|
  t.pattern = 'spec/integration/*_spec.rb'
end

desc "Print specdocs"
RSpec::Core::RakeTask.new(:doc) do |t|
  t.rspec_opts = ["--format", "specdoc", "--dry-run"]
  t.pattern = 'spec/**/*_spec.rb'
end

desc "Run all examples with RCov"
RSpec::Core::RakeTask.new('rcov') do |t|
  t.pattern = 'spec/*_spec.rb'
  t.rcov = true
  t.rcov_opts = ['--exclude', 'examples']
end

desc 'Regenerate authors file'
task :authors do
  Dir.chdir(File.dirname(__FILE__)) do
    File.open('AUTHORS', 'w') do |f|
      f.write <<-EOM
The Ruby REST Client would not be what it is today without the help of
the following kind souls:

      EOM
    end

    sh 'git shortlog -s | cut -f 2 >> AUTHORS'
  end
end

task :default do
  sh 'rake -T'
end

def alias_task(alias_task, original)
  desc "Alias for rake #{original}"
  task alias_task, Rake.application[original].arg_names => original
end
alias_task(:test, :spec)

############################

WindowsPlatforms = %w{x86-mingw32 x64-mingw32 x86-mswin32}

namespace :all do

  desc "Build rest-client #{RestClient::VERSION} for all platforms"
  task :build => ['ruby:build'] + \
    WindowsPlatforms.map {|p| "windows:#{p}:build"}

  desc "Create tag v#{RestClient::VERSION} and for all platforms build and " \
    "push rest-client #{RestClient::VERSION} to Rubygems"
  task :release => ['build', 'ruby:release'] + \
    WindowsPlatforms.map {|p| "windows:#{p}:push"}

end

namespace :windows do
  spec_path = File.join(File.dirname(__FILE__), 'rest-client.windows.gemspec')

  WindowsPlatforms.each do |platform|
    namespace platform do
      gem_filename = "rest-client-#{RestClient::VERSION}-#{platform}.gem"
      base = File.dirname(__FILE__)
      pkg_dir = File.join(base, 'pkg')
      gem_file_path = File.join(pkg_dir, gem_filename)

      desc "Build #{gem_filename} into the pkg directory"
      task 'build' do
        orig_platform = ENV['BUILD_PLATFORM']
        begin
          ENV['BUILD_PLATFORM'] = platform

          sh("gem build -V #{spec_path}") do |ok, res|
            if ok
              FileUtils.mkdir_p(pkg_dir)
              FileUtils.mv(File.join(base, gem_filename), pkg_dir)
              Bundler.ui.confirm("rest-client #{RestClient::VERSION} " \
                                 "built to pkg/#{gem_filename}")
            else
              abort "Command `gem build` failed: #{res}"
            end
          end

        ensure
          ENV['BUILD_PLATFORM'] = orig_platform
        end
      end

      desc "Push #{gem_filename} to Rubygems"
      task 'push' do
        sh("gem push #{gem_file_path}")
      end
    end
  end

end

############################

require 'rdoc/task'

Rake::RDocTask.new do |t|
  t.rdoc_dir = 'rdoc'
  t.title    = "rest-client, fetch RESTful resources effortlessly"
  t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
  t.options << '--charset' << 'utf-8'
  t.rdoc_files.include('README.md')
  t.rdoc_files.include('lib/*.rb')
end

############################

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end
alias_task(:lint, :rubocop)
