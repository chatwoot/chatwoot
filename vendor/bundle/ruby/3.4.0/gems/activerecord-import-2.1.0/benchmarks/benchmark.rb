# frozen_string_literal: true

require 'pathname'
require "fileutils"
require "active_record"
require "active_record/base"

benchmark_dir = File.dirname(__FILE__)

$LOAD_PATH.unshift('.')

# Get the gem into the load path
$LOAD_PATH.unshift(File.join(benchmark_dir, '..', 'lib'))

# Load the benchmark files
Dir[File.join( benchmark_dir, 'lib', '*.rb' )].sort.each { |f| require f }

# Parse the options passed in via the command line
options = BenchmarkOptionParser.parse( ARGV )

FileUtils.mkdir_p 'log'
ActiveRecord::Base.configurations["test"] = YAML.load_file(File.join(benchmark_dir, "../test/database.yml"))[options.adapter]
ActiveRecord::Base.logger = Logger.new("log/test.log")
ActiveRecord::Base.logger.level = Logger::DEBUG
if ActiveRecord.respond_to?(:default_timezone)
  ActiveRecord.default_timezone = :utc
else
  ActiveRecord::Base.default_timezone = :utc
end

require "activerecord-import"
ActiveRecord::Base.establish_connection(:test)

ActiveSupport::Notifications.subscribe(/active_record.sql/) do |_, _, _, _, hsh|
  ActiveRecord::Base.logger.info hsh[:sql]
end

# Load base/generic schema
require File.join(benchmark_dir, "../test/schema/version")
require File.join(benchmark_dir, "../test/schema/generic_schema")
adapter_schema = File.join(benchmark_dir, "schema/#{options.adapter}_schema.rb")
require adapter_schema if File.exist?(adapter_schema)

Dir["#{File.dirname(__FILE__)}/models/*.rb"].sort.each { |file| require file }

require File.join( benchmark_dir, 'lib', "#{options.adapter}_benchmark" )
table_types = if options.benchmark_all_types
  ["all"]
else
  options.table_types.keys
end

letter = options.adapter[0].chr
clazz_str = letter.upcase + options.adapter[1..].downcase
clazz = Object.const_get( "#{clazz_str}Benchmark" )

benchmarks = []
options.number_of_objects.each do |num|
  benchmarks << (benchmark = clazz.new)
  benchmark.send( "benchmark", table_types, num )
end

options.outputs.each do |output|
  format = output.format.downcase
  output_module = Object.const_get( "OutputTo#{format.upcase}" )
  benchmarks.each do |benchmark|
    output_module.output_results( output.filename, benchmark.results )
  end
end

puts
puts "Done with benchmark!"
