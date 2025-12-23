# frozen_string_literal: true

require "rubygems"

module Sentry
  # @api private
  class Backtrace
    # Handles backtrace parsing line by line
    class Line
      RB_EXTENSION = ".rb"
      # regexp (optional leading X: on windows, or JRuby9000 class-prefix)
      RUBY_INPUT_FORMAT = /
        ^ \s* (?: [a-zA-Z]: | uri:classloader: )? ([^:]+ | <.*>):
        (\d+)
        (?: :in\s('|`)([^']+)')?$
      /x.freeze

      # org.jruby.runtime.callsite.CachingCallSite.call(CachingCallSite.java:170)
      JAVA_INPUT_FORMAT = /^(.+)\.([^\.]+)\(([^\:]+)\:(\d+)\)$/.freeze

      # The file portion of the line (such as app/models/user.rb)
      attr_reader :file

      # The line number portion of the line
      attr_reader :number

      # The method of the line (such as index)
      attr_reader :method

      # The module name (JRuby)
      attr_reader :module_name

      attr_reader :in_app_pattern

      # Parses a single line of a given backtrace
      # @param [String] unparsed_line The raw line from +caller+ or some backtrace
      # @return [Line] The parsed backtrace line
      def self.parse(unparsed_line, in_app_pattern = nil)
        ruby_match = unparsed_line.match(RUBY_INPUT_FORMAT)
        if ruby_match
          _, file, number, _, method = ruby_match.to_a
          file.sub!(/\.class$/, RB_EXTENSION)
          module_name = nil
        else
          java_match = unparsed_line.match(JAVA_INPUT_FORMAT)
          _, module_name, method, file, number = java_match.to_a
        end
        new(file, number, method, module_name, in_app_pattern)
      end

      def initialize(file, number, method, module_name, in_app_pattern)
        @file = file
        @module_name = module_name
        @number = number.to_i
        @method = method
        @in_app_pattern = in_app_pattern
      end

      def in_app
        return false unless in_app_pattern

        if file =~ in_app_pattern
          true
        else
          false
        end
      end

      # Reconstructs the line in a readable fashion
      def to_s
        "#{file}:#{number}:in `#{method}'"
      end

      def ==(other)
        to_s == other.to_s
      end

      def inspect
        "<Line:#{self}>"
      end
    end

    APP_DIRS_PATTERN = /(bin|exe|app|config|lib|test|spec)/.freeze

    # holder for an Array of Backtrace::Line instances
    attr_reader :lines

    def self.parse(backtrace, project_root, app_dirs_pattern, &backtrace_cleanup_callback)
      ruby_lines = backtrace.is_a?(Array) ? backtrace : backtrace.split(/\n\s*/)

      ruby_lines = backtrace_cleanup_callback.call(ruby_lines) if backtrace_cleanup_callback

      in_app_pattern ||= begin
        Regexp.new("^(#{project_root}/)?#{app_dirs_pattern || APP_DIRS_PATTERN}")
      end

      lines = ruby_lines.to_a.map do |unparsed_line|
        Line.parse(unparsed_line, in_app_pattern)
      end

      new(lines)
    end

    def initialize(lines)
      @lines = lines
    end

    def inspect
      "<Backtrace: " + lines.map(&:inspect).join(", ") + ">"
    end

    def to_s
      content = []
      lines.each do |line|
        content << line
      end
      content.join("\n")
    end

    def ==(other)
      if other.respond_to?(:lines)
        lines == other.lines
      else
        false
      end
    end
  end
end
