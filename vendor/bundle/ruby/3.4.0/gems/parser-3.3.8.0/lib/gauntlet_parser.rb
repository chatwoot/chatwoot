# frozen_string_literal: true

require 'gauntlet'
require_relative 'parser/all'
require 'shellwords'

class ParserGauntlet < Gauntlet
  RUBY20 = 'ruby'
  RUBY19 = 'ruby1.9.1'
  RUBY18 = '/opt/rubies/ruby-1.8.7-p370/bin/ruby'

  def try(parser, ruby, file, show_ok: false)
    try_ruby = lambda do |e|
      Process.spawn(%{#{ruby} -c #{Shellwords.escape file}},
                    :err => '/dev/null', :out => '/dev/null')
      _, status = Process.wait2

      if status.success?
        # Bug in Parser.
        puts "Parser bug."
        @result[file] = { parser.to_s => "#{e.class}: #{e.to_s}" }
      else
        # No, this file is not Ruby.
        yield if block_given?
      end
    end

    begin
      parser.parse_file(file)

    rescue Parser::SyntaxError => e
      if e.diagnostic.location.resize(2).is?('<%')
        puts "ERb."
        return
      end

      try_ruby.call(e)

    rescue ArgumentError, RegexpError,
           Encoding::UndefinedConversionError => e
      puts "#{file}: #{e.class}: #{e.to_s}"

      try_ruby.call(e)

    rescue Interrupt
      raise

    rescue Exception => e
      puts "Parser bug: #{file} #{e.class}: #{e.to_s}"
      @result[file] = { parser.to_s => "#{e.class}: #{e.to_s}" }

    else
      puts "Ok." if show_ok
    end
  end

  def parse(name)
    puts "GEM: #{name}"

    @result = {}

    if ENV.include?('FAST')
      total_size = Dir["**/*.rb"].map(&File.method(:size)).reduce(:+)
      if total_size > 300_000
        puts "Skip."
        return
      end
    end

    Dir["**/*.rb"].each do |file|
      next if File.directory? file

      try(Parser::Ruby20, RUBY20, file) do
        puts "Trying 1.9:"
        try(Parser::Ruby19, RUBY19, file, show_ok: true) do
          puts "Trying 1.8:"
          try(Parser::Ruby18, RUBY18, file, show_ok: true) do
            puts "Invalid syntax."
          end
        end
      end
    end

    @result
  end

  def run(name)
    data[name] = parse(name)
    self.dirty = true
  end

  def should_skip?(name)
    data[name] == {}
  end

  def load_yaml(*)
    data = super
    @was_errors = data.count { |_name, errs| errs != {} }

    data
  end

  def shutdown
    super

    errors  = data.count { |_name, errs| errs != {} }
    total   = data.count
    percent = "%.5f" % [100 - errors.to_f / total * 100]
    puts "!!! was: #{@was_errors} now: #{errors} total: #{total} frac: #{percent}%"
  end
end

filter = ARGV.shift
filter = Regexp.new filter if filter

gauntlet = ParserGauntlet.new

if ENV.include? 'UPDATE'
  gauntlet.source_index
  gauntlet.update_gem_tarballs
end

gauntlet.run_the_gauntlet filter
