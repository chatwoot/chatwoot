# frozen_string_literal: true

require "socket"
require "time"

require "rspec/core"
require "rspec/core/formatters/base_formatter"

# Dumps rspec results as a JUnit XML file.
# Based on XML schema: http://windyroad.org/dl/Open%20Source/JUnit.xsd
class RSpecJUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  # rspec 2 and 3 implements are in separate files.

private

  def xml_dump
    output << %{<?xml version="1.0" encoding="UTF-8"?>\n}
    output << %{<testsuite}
    output << %{ name="rspec#{escape(ENV["TEST_ENV_NUMBER"].to_s)}"}
    output << %{ tests="#{example_count}"}
    output << %{ skipped="#{pending_count}"}
    output << %{ failures="#{failure_count}"}
    output << %{ errors="#{error_count}"}
    output << %{ time="#{escape("%.6f" % duration)}"}
    output << %{ timestamp="#{escape(started.iso8601)}"}
    output << %{ hostname="#{escape(Socket.gethostname)}"}
    output << %{>\n}
    output << %{<properties>\n}
    output << %{<property}
    output << %{ name="seed"}
    output << %{ value="#{escape(RSpec.configuration.seed.to_s)}"}
    output << %{/>\n}
    output << %{</properties>\n}
    xml_dump_examples
    output << %{</testsuite>\n}
  end

  def xml_dump_examples
    examples.each do |example|
      case result_of(example)
      when :pending
        xml_dump_pending(example)
      when :failed
        xml_dump_failed(example)
      else
        xml_dump_example(example)
      end
    end
  end

  def xml_dump_pending(example)
    xml_dump_example(example) do
      output << %{<skipped/>}
    end
  end

  def xml_dump_failed(example)
    xml_dump_example(example) do
      output << %{<failure}
      output << %{ message="#{escape(failure_message_for(example))}"}
      output << %{ type="#{escape(failure_type_for(example))}"}
      output << %{>}
      output << escape(failure_for(example))
      output << %{</failure>}
    end
  end

  def xml_dump_example(example)
    output << %{<testcase}
    output << %{ classname="#{escape(classname_for(example))}"}
    output << %{ name="#{escape(description_for(example))}"}
    output << %{ file="#{escape(example_group_file_path_for(example))}"}
    if duration = duration_for(example)
      output << %{ time="#{escape("%.6f" % duration)}"}
    end
    output << %{>}
    yield if block_given?
    xml_dump_output(example)
    output << %{</testcase>\n}
  end

  def xml_dump_output(example)
    if (stdout = stdout_for(example)) && !stdout.empty?
      output << %{<system-out>}
      output << escape(stdout)
      output << %{</system-out>}
    end

    if (stderr = stderr_for(example)) && !stderr.empty?
      output << %{<system-err>}
      output << escape(stderr)
      output << %{</system-err>}
    end
  end

  # Inversion of character range from https://www.w3.org/TR/xml/#charsets
  ILLEGAL_REGEXP = Regexp.new(
    "[^".dup <<
    "\u{9}" << # => \t
    "\u{a}" << # => \n
    "\u{d}" << # => \r
    "\u{20}-\u{d7ff}" <<
    "\u{e000}-\u{fffd}" <<
    "\u{10000}-\u{10ffff}" <<
    "]"
  )

  # Replace illegals with a Ruby-like escape
  ILLEGAL_REPLACEMENT = Hash.new { |_, c|
    x = c.ord
    if x <= 0xff
      "\\x%02X".freeze % x
    elsif x <= 0xffff
      "\\u%04X".freeze % x
    else
      "\\u{%X}".freeze % x
    end.freeze
  }.update(
    "\0".freeze => "\\0".freeze,
    "\a".freeze => "\\a".freeze,
    "\b".freeze => "\\b".freeze,
    "\f".freeze => "\\f".freeze,
    "\v".freeze => "\\v".freeze,
    "\e".freeze => "\\e".freeze,
  ).freeze

  # Discouraged characters from https://www.w3.org/TR/xml/#charsets
  # Plus special characters with well-known entity replacements
  DISCOURAGED_REGEXP = Regexp.new(
    "[".dup <<
    "\u{22}" << # => "
    "\u{26}" << # => &
    "\u{27}" << # => '
    "\u{3c}" << # => <
    "\u{3e}" << # => >
    "\u{7f}-\u{84}" <<
    "\u{86}-\u{9f}" <<
    "\u{fdd0}-\u{fdef}" <<
    "\u{1fffe}-\u{1ffff}" <<
    "\u{2fffe}-\u{2ffff}" <<
    "\u{3fffe}-\u{3ffff}" <<
    "\u{4fffe}-\u{4ffff}" <<
    "\u{5fffe}-\u{5ffff}" <<
    "\u{6fffe}-\u{6ffff}" <<
    "\u{7fffe}-\u{7ffff}" <<
    "\u{8fffe}-\u{8ffff}" <<
    "\u{9fffe}-\u{9ffff}" <<
    "\u{afffe}-\u{affff}" <<
    "\u{bfffe}-\u{bffff}" <<
    "\u{cfffe}-\u{cffff}" <<
    "\u{dfffe}-\u{dffff}" <<
    "\u{efffe}-\u{effff}" <<
    "\u{ffffe}-\u{fffff}" <<
    "\u{10fffe}-\u{10ffff}" <<
    "]"
  )

  # Translate well-known entities, or use generic unicode hex entity
  DISCOURAGED_REPLACEMENTS = Hash.new { |_, c| "&#x#{c.ord.to_s(16)};".freeze }.update(
    ?".freeze => "&quot;".freeze,
    ?&.freeze => "&amp;".freeze,
    ?'.freeze => "&apos;".freeze,
    ?<.freeze => "&lt;".freeze,
    ?>.freeze => "&gt;".freeze,
  ).freeze

  def escape(text)
    # Make sure it's utf-8, replace illegal characters with ruby-like escapes, and replace special and discouraged characters with entities
    text.to_s.encode(Encoding::UTF_8).gsub(ILLEGAL_REGEXP, ILLEGAL_REPLACEMENT).gsub(DISCOURAGED_REGEXP, DISCOURAGED_REPLACEMENTS)
  end

  STRIP_DIFF_COLORS_BLOCK_REGEXP = /^ ( [ ]* ) Diff: (?: \e\[ 0 m )? (?: \n \1 \e\[ \d+ (?: ; \d+ )* m .* )* /x
  STRIP_DIFF_COLORS_CODES_REGEXP = /\e\[ \d+ (?: ; \d+ )* m/x

  def strip_diff_colors(string)
    # XXX: RSpec diffs are appended to the message lines fairly early and will
    # contain ANSI escape codes for colorizing terminal output if the global
    # rspec configuration is turned on, regardless of which notification lines
    # we ask for. We need to strip the codes from the diff part of the message
    # for XML output here.
    #
    # We also only want to target the diff hunks because the failure message
    # itself might legitimately contain ansi escape codes.
    #
    string.sub(STRIP_DIFF_COLORS_BLOCK_REGEXP) { |match| match.gsub(STRIP_DIFF_COLORS_CODES_REGEXP, "".freeze) }
  end
end

RspecJunitFormatter = RSpecJUnitFormatter

if Gem::Version.new(RSpec::Core::Version::STRING) >= Gem::Version.new("3")
  require "rspec_junit_formatter/rspec3"
else
  require "rspec_junit_formatter/rspec2"
end
