# frozen_string_literal: true

require "bundler"
Bundler.setup

require 'rake'
require 'rake/testtask'

namespace :display do
  task :notice do
    puts
    puts "To run tests you must supply the adapter, see rake -T for more information."
    puts
  end
end
task default: ["display:notice"]

ADAPTERS = %w(
  mysql2
  mysql2_makara
  mysql2spatial
  mysql2_proxy
  jdbcmysql
  jdbcsqlite3
  jdbcpostgresql
  postgresql
  postgresql_makara
  postgresql_proxy
  postgis
  makara_postgis
  sqlite3
  spatialite
  seamless_database_pool
  trilogy
).freeze
ADAPTERS.each do |adapter|
  namespace :test do
    desc "Runs #{adapter} database tests."
    Rake::TestTask.new(adapter) do |t|
      # FactoryBot has an issue with warnings, so turn off, so noisy
      # t.warning = true
      t.test_files = FileList["test/adapters/#{adapter}.rb", "test/*_test.rb", "test/active_record/*_test.rb", "test/#{adapter}/**/*_test.rb"]
    end
    task adapter
  end
end

begin
  require 'rcov/rcovtask'
  adapter = ENV['ARE_DB']
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = ["test/adapters/#{adapter}.rb", "test/*_test.rb", "test/#{adapter}/**/*_test.rb"]
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install rcov"
  end
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "activerecord-import #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new
