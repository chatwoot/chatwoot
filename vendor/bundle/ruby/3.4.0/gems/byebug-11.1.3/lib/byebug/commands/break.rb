# frozen_string_literal: true

require_relative "../command"
require_relative "../helpers/eval"
require_relative "../helpers/file"
require_relative "../helpers/parse"
require_relative "../source_file_formatter"

module Byebug
  #
  # Implements breakpoint functionality
  #
  class BreakCommand < Command
    include Helpers::EvalHelper
    include Helpers::FileHelper
    include Helpers::ParseHelper

    self.allow_in_control = true

    def self.regexp
      /^\s* b(?:reak)? (?:\s+ (.+?))? (?:\s+ if \s+(.+))? \s*$/x
    end

    def self.description
      <<-DESCRIPTION
        b[reak] [<file>:]<line> [if <expr>]
        b[reak] [<module>::...]<class>(.|#)<method> [if <expr>]

        They can be specified by line or method and an expression can be added
        for conditionally enabled breakpoints.

        #{short_description}
      DESCRIPTION
    end

    def self.short_description
      "Sets breakpoints in the source code"
    end

    def execute
      return puts(help) unless @match[1]

      b = line_breakpoint(@match[1]) || method_breakpoint(@match[1])
      return errmsg(pr("break.errors.location")) unless b

      return puts(pr("break.created", id: b.id, file: b.source, line: b.pos)) if syntax_valid?(@match[2])

      errmsg(pr("break.errors.expression", expr: @match[2]))
      b.enabled = false
    end

    private

    def line_breakpoint(location)
      line_match = location.match(/^(\d+)$/)
      file_line_match = location.match(/^(.+):(\d+)$/)
      return unless line_match || file_line_match

      file = line_match ? frame.file : file_line_match[1]
      line = line_match ? line_match[1].to_i : file_line_match[2].to_i

      add_line_breakpoint(file, line)
    end

    def method_breakpoint(location)
      location.match(/([^.#]+)[.#](.+)/) do |match|
        klass = target_object(match[1])
        method = match[2].intern

        Breakpoint.add(klass, method, @match[2])
      end
    end

    def target_object(str)
      k = error_eval(str)

      k&.is_a?(Module) ? k.name : str
    rescue StandardError
      errmsg("Warning: breakpoint source is not yet defined")
      str
    end

    def add_line_breakpoint(file, line)
      raise(pr("break.errors.source", file: file)) unless File.exist?(file)

      fullpath = File.realpath(file)

      raise(pr("break.errors.far_line", lines: n_lines(file), file: fullpath)) if line > n_lines(file)

      unless Breakpoint.potential_line?(fullpath, line)
        msg = pr(
          "break.errors.line",
          file: fullpath,
          line: line,
          valid_breakpoints: valid_breakpoints_for(fullpath, line)
        )

        raise(msg)
      end

      Breakpoint.add(fullpath, line, @match[2])
    end

    def valid_breakpoints_for(path, line)
      potential_lines = Breakpoint.potential_lines(path)
      annotator = ->(n) { potential_lines.include?(n) ? "[B]" : "   " }
      source_file_formatter = SourceFileFormatter.new(path, annotator)

      source_file_formatter.lines_around(line).join.chomp
    end
  end
end
