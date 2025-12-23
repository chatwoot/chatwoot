# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'helpers/matches'
include Matches

begin
  require 'rake/testtask'
rescue LoadError
end

if defined? Rake::TestTask
  def name_for_number(content, number)
    (number - 1).downto(0).each do |i|
      return Regexp.last_match(1) if content[i] =~ /^\s*def (test_.+)\s*$/
    end
  end

  def info_from_test_var
    return {} unless ENV['TEST'].to_s =~ /^(.+)((?::\d+)+)/

    file = Regexp.last_match(1)
    numbers = Regexp.last_match(2).split(':').reject(&:empty?).uniq.map(&:to_i)
    abs = File.expand_path(File.join('../../..', file), __FILE__)
    raise "File >>#{abs}<< does not exist!" unless File.exist?(abs)

    content = File.read(abs).split("\n")
    {file: file, numbers: numbers, content: content}
  end

  def test_names_from_test_file(info)
    info[:numbers].each_with_object([]) do |number, names|
      name = name_for_number(info[:content], number)
      unless name
        warn "Unable to determine a test name given line >>#{number}<< for file >>#{info[:file]}<<"
        next
      end
      names << name
    end
  end

  # Allow ENV['TEST'] to be set to a test file path with one or more
  # `:<line number>` patterns on the end of it.
  #
  # For example:
  #   TEST=test/new_relic/agent/autostart_test.rb:57 bundle exec rake test
  #
  # The `autostart_test.rb` file will be read, and starting from line 57 and
  # working upwards in the file (downwards by line number), a test definition
  # will be searched for that matches `def test_<rest of the test name>`.
  #
  # Multiple line numbers can be specified like so:
  #   TEST=test/new_relic/agent/autostart_test.rb:57:26 bundle exec rake test
  #
  # For this multiple line number based example, both lines 57 and 26 will
  # serve as separate starting points for the search for a test name.
  #
  # All test names that are discovered will be "ORed" into a regex pattern with
  # pipes ('|') that is passed to Minitest via
  #   `TESTOPTS="--name='test_name1|test_name2'"`
  #
  # Once a line with one or more `:<line number>` values on the end of it has
  # been found, replace the value of ENV['TEST'] with the path leading up to
  # the first colon before invoking Minitest.
  #
  # Why refer to a test by line number instead of just supplying the name
  # directly? The primary use case is text editor integration. A text editor
  # can be taught to "run the single unit test containing the line the cursor is
  # on" by building a string containing the path to the file, a colon, (':'),
  # and the line number.
  def process_line_numbers
    info = info_from_test_var
    return unless info.key?(:file)

    test_names = test_names_from_test_file(info)
    raise "Could not determine any test names for file >>#{abs}<< given numbers >>#{numbers}" if test_names.empty?

    ENV['TESTOPTS'] = "#{ENV['TESTOPTS']} --name='#{test_names.map { |n| Regexp.escape(n) }.join('|')}'"
    ENV['TEST'] = info[:file]
  end

  namespace :test do
    tasks = Rake.application.top_level_tasks
    ENV['TESTOPTS'] ||= ''
    if tasks.any? { |t| t.include?('verbose') }
      ENV['TESTOPTS'] += ' -v'
    end
    if seed = look_for_seed(tasks)
      ENV['TESTOPTS'] += ' --' + seed
    end

    process_line_numbers

    agent_home = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

    Rake::TestTask.new(:newrelic) do |t|
      file_pattern = ENV['file']
      file_pattern = file_pattern.split(',').map { |f| "#{agent_home}/#{f}".gsub('//', '/') } if file_pattern
      file_pattern ||= "#{agent_home}/test/new_relic/**/*_test.rb"

      t.libs << "#{agent_home}/test"
      t.libs << "#{agent_home}/lib"
      t.pattern = Array(file_pattern)
    end
  end
end
