# frozen_string_literal: true

require_relative "string_prep_tables_generator"

generator = StringPrepTablesGenerator.new

file generator.json_filename => generator.json_deps do |t|
  generator.generate_json_data_file
end

directory "lib/net/imap/sasl"

file "lib/net/imap/stringprep/tables.rb" => generator.rb_deps do |t|
  File.write t.name, generator.stringprep_rb
end

file "lib/net/imap/stringprep/saslprep_tables.rb" => generator.rb_deps do |t|
  File.write t.name, generator.saslprep_rb
end

GENERATED_RUBY = FileList.new(
  "lib/net/imap/stringprep/tables.rb",
  "lib/net/imap/stringprep/saslprep_tables.rb",
)

CLEAN.include   generator.clean_deps
CLOBBER.include GENERATED_RUBY

task saslprep_rb: GENERATED_RUBY
task test: :saslprep_rb
