# frozen_string_literal: true

PARSER_TEST_FIXTURES = FileList.new "test/net/imap/fixtures/response_parser/*.yml"
CLOBBER.include "benchmarks/parser.yml"
CLEAN.include   "benchmarks/Gemfile-*"

BENCHMARK_INIT = <<RUBY
  require "yaml"
  require "net/imap"

  def load_response(file, name)
    YAML.unsafe_load_file(file).dig(:tests, name, :response)
      .force_encoding "ASCII-8BIT" \\
      or abort "ERRORO: missing %p fixture data in %p" % [name, file]
  end

  parser   = Net::IMAP::ResponseParser.new
RUBY

file "benchmarks/parser.yml" => PARSER_TEST_FIXTURES do |t|
  require "yaml"
  require "pathname"
  require "net/imap"

  path = Pathname.new(__dir__) / "../test/net/imap/fixtures/response_parser"
  files = path.glob("*.yml")
  tests = files.flat_map {|file|
    file.read
      .gsub(%r{([-:]) !ruby/(object|struct|array):\S+}) { $1 }
      .then {
        YAML.safe_load(_1, filename: file,
                       permitted_classes: [Symbol, Regexp], aliases: true)
      }
      .fetch(:tests)
      .select {|test_name, test|
        :parser_assert_equal == test.fetch(:test_type) {
          test.key?(:expected) ? :parser_assert_equal : :parser_pending
        }
      }
      .map {|test_name, test| [test_name.to_s, test.fetch(:response)] }
  }

  benchmarks = tests.map {|fixture_name, response|
    {"name"    => fixture_name.delete_prefix("test_"),
     "prelude" => "response = -%s.b" % [response.dump],
     "script"  => "parser.parse(response)"}
  }
    .sort_by { _1["name"] }

  YAML.dump({"prelude" => BENCHMARK_INIT, "benchmark" => benchmarks})
    .then { File.write t.name, _1 }
end

namespace :benchmarks do
  desc "Generate benchmarks from fixture data"
  task :generate => "benchmarks/parser.yml"

  desc "run the parser benchmarks comparing multiple gem versions"
  task :compare => :generate do |task, args|
    cd Pathname.new(__dir__) + ".."
    current = `git describe --tags --dirty`.chomp
    current = "dev" if current.empty?
    versions = args.to_a
    if versions.empty?
      latest = %x{git describe --tags --abbrev=0 --match 'v*.*.*'}.chomp
      versions = latest.empty? ? [] : [latest.delete_prefix("v")]
    end
    versions = versions.to_h { [_1, "Gemfile-v#{_1}"] }
    cd "benchmarks" do
      versions.each do |version, gemfile|
        File.write gemfile, <<~RUBY
          # frozen_string_literal: true
          source "https://rubygems.org"
          gem "net-imap", #{version.dump}
        RUBY
      end
      versions = {current => "../Gemfile" , **versions}.map {
        "%s::/usr/bin/env BUNDLE_GEMFILE=%s ruby" % _1
      }.join(";")

      extra = ENV.fetch("BENCHMARK_ARGS", "").shellsplit

      sh("benchmark-driver",
         "--bundler",
         "-e", versions,
         "parser.yml",
         *extra)
    end
  end

end
