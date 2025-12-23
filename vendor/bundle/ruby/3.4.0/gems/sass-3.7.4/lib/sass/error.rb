module Sass
  # An exception class that keeps track of
  # the line of the Sass template it was raised on
  # and the Sass file that was being parsed (if applicable).
  #
  # All Sass errors are raised as {Sass::SyntaxError}s.
  #
  # When dealing with SyntaxErrors,
  # it's important to provide filename and line number information.
  # This will be used in various error reports to users, including backtraces;
  # see \{#sass\_backtrace} for details.
  #
  # Some of this information is usually provided as part of the constructor.
  # New backtrace entries can be added with \{#add\_backtrace},
  # which is called when an exception is raised between files (e.g. with `@import`).
  #
  # Often, a chunk of code will all have similar backtrace information -
  # the same filename or even line.
  # It may also be useful to have a default line number set.
  # In those situations, the default values can be used
  # by omitting the information on the original exception,
  # and then calling \{#modify\_backtrace} in a wrapper `rescue`.
  # When doing this, be sure that all exceptions ultimately end up
  # with the information filled in.
  class SyntaxError < StandardError
    # The backtrace of the error within Sass files.
    # This is an array of hashes containing information for a single entry.
    # The hashes have the following keys:
    #
    # `:filename`
    # : The name of the file in which the exception was raised,
    #   or `nil` if no filename is available.
    #
    # `:mixin`
    # : The name of the mixin in which the exception was raised,
    #   or `nil` if it wasn't raised in a mixin.
    #
    # `:line`
    # : The line of the file on which the error occurred. Never nil.
    #
    # This information is also included in standard backtrace format
    # in the output of \{#backtrace}.
    #
    # @return [Aray<{Symbol => Object>}]
    attr_accessor :sass_backtrace

    # The text of the template where this error was raised.
    #
    # @return [String]
    attr_accessor :sass_template

    # @param msg [String] The error message
    # @param attrs [{Symbol => Object}] The information in the backtrace entry.
    #   See \{#sass\_backtrace}
    def initialize(msg, attrs = {})
      @message = msg
      @sass_backtrace = []
      add_backtrace(attrs)
    end

    # The name of the file in which the exception was raised.
    # This could be `nil` if no filename is available.
    #
    # @return [String, nil]
    def sass_filename
      sass_backtrace.first[:filename]
    end

    # The name of the mixin in which the error occurred.
    # This could be `nil` if the error occurred outside a mixin.
    #
    # @return [String]
    def sass_mixin
      sass_backtrace.first[:mixin]
    end

    # The line of the Sass template on which the error occurred.
    #
    # @return [Integer]
    def sass_line
      sass_backtrace.first[:line]
    end

    # Adds an entry to the exception's Sass backtrace.
    #
    # @param attrs [{Symbol => Object}] The information in the backtrace entry.
    #   See \{#sass\_backtrace}
    def add_backtrace(attrs)
      sass_backtrace << attrs.reject {|_k, v| v.nil?}
    end

    # Modify the top Sass backtrace entries
    # (that is, the most deeply nested ones)
    # to have the given attributes.
    #
    # Specifically, this goes through the backtrace entries
    # from most deeply nested to least,
    # setting the given attributes for each entry.
    # If an entry already has one of the given attributes set,
    # the pre-existing attribute takes precedence
    # and is not used for less deeply-nested entries
    # (even if they don't have that attribute set).
    #
    # @param attrs [{Symbol => Object}] The information to add to the backtrace entry.
    #   See \{#sass\_backtrace}
    def modify_backtrace(attrs)
      attrs = attrs.reject {|_k, v| v.nil?}
      # Move backwards through the backtrace
      (0...sass_backtrace.size).to_a.reverse_each do |i|
        entry = sass_backtrace[i]
        sass_backtrace[i] = attrs.merge(entry)
        attrs.reject! {|k, _v| entry.include?(k)}
        break if attrs.empty?
      end
    end

    # @return [String] The error message
    def to_s
      @message
    end

    # Returns the standard exception backtrace,
    # including the Sass backtrace.
    #
    # @return [Array<String>]
    def backtrace
      return nil if super.nil?
      return super if sass_backtrace.all? {|h| h.empty?}
      sass_backtrace.map do |h|
        "#{h[:filename] || '(sass)'}:#{h[:line]}" +
          (h[:mixin] ? ":in `#{h[:mixin]}'" : "")
      end + super
    end

    # Returns a string representation of the Sass backtrace.
    #
    # @param default_filename [String] The filename to use for unknown files
    # @see #sass_backtrace
    # @return [String]
    def sass_backtrace_str(default_filename = "an unknown file")
      lines = message.split("\n")
      msg = lines[0] + lines[1..-1].
        map {|l| "\n" + (" " * "Error: ".size) + l}.join
      "Error: #{msg}" +
        sass_backtrace.each_with_index.map do |entry, i|
          "\n        #{i == 0 ? 'on' : 'from'} line #{entry[:line]}" +
            " of #{entry[:filename] || default_filename}" +
            (entry[:mixin] ? ", in `#{entry[:mixin]}'" : "")
        end.join
    end

    class << self
      # Returns an error report for an exception in CSS format.
      #
      # @param e [Exception]
      # @param line_offset [Integer] The number of the first line of the Sass template.
      # @return [String] The error report
      # @raise [Exception] `e`, if the
      #   {file:SASS_REFERENCE.md#full_exception-option `:full_exception`} option
      #   is set to false.
      def exception_to_css(e, line_offset = 1)
        header = header_string(e, line_offset)

        <<END
/*
#{header.gsub('*/', '*\\/')}

Backtrace:\n#{e.backtrace.join("\n").gsub('*/', '*\\/')}
*/
body:before {
  white-space: pre;
  font-family: monospace;
  content: "#{header.gsub('"', '\"').gsub("\n", '\\A ')}"; }
END
      end

      private

      def header_string(e, line_offset)
        unless e.is_a?(Sass::SyntaxError) && e.sass_line && e.sass_template
          return "#{e.class}: #{e.message}"
        end

        line_num = e.sass_line + 1 - line_offset
        min = [line_num - 6, 0].max
        section = e.sass_template.rstrip.split("\n")[min...line_num + 5]
        return e.sass_backtrace_str if section.nil? || section.empty?

        e.sass_backtrace_str + "\n\n" + section.each_with_index.
          map {|line, i| "#{line_offset + min + i}: #{line}"}.join("\n")
      end
    end
  end

  # The class for Sass errors that are raised due to invalid unit conversions
  # in SassScript.
  class UnitConversionError < SyntaxError; end
end
