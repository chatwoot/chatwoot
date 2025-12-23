# frozen_string_literal: true

require 'tempfile'

class Pry
  module Helpers
    module CommandHelpers
      include OptionsHelpers

      extend self

      # Open a temp file and yield it to the block, closing it after
      # @return [String] The path of the temp file
      def temp_file(ext = '.rb')
        file = Tempfile.new(['pry', ext])
        yield(file)
      ensure
        file.close(true)
      end

      def internal_binding?(context)
        method_name = context.eval("::Kernel.__method__").to_s
        # class_eval is here because of http://jira.codehaus.org/browse/JRUBY-6753
        %w[__binding__ __pry__ class_eval].include?(method_name)
        # TODO: codehaus is dead, there was no test for this and the
        # description for the commit doesn't exist. Probably a candidate for
        # removal so we have a chance to introduce a regression and document it
        # properly.
      end

      def get_method_or_raise(method_name, context, opts = {})
        method = Pry::Method.from_str(method_name, context, opts)
        if !method && method_name
          raise Pry::MethodNotFound, "method '#{method_name}' could not be found."
        end

        (opts[:super] || 0).times do
          if method.super
            method = method.super
          else
            raise Pry::MethodNotFound,
                  "'#{method.name_with_owner}' has no super method"
          end
        end

        if !method || (!method_name && internal_binding?(context))
          raise Pry::MethodNotFound,
                'no method name given, and context is not a method'
        end

        set_file_and_dir_locals(method.source_file)
        method
      end

      # Remove any common leading whitespace from every line in `text`. This
      # can be used to make a HEREDOC line up with the left margin, without
      # sacrificing the indentation level of the source code.
      #
      # @example
      #   opt.banner(unindent(<<-USAGE))
      #     Lorem ipsum dolor sit amet, consectetur adipisicing elit,
      #     sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
      #       "Ut enim ad minim veniam."
      #   USAGE
      #
      # @param [String] dirty_text The text from which to remove indentation
      # @return [String] the text with indentation stripped
      def unindent(dirty_text, left_padding = 0)
        text = dirty_text.sub(/\A[ \t]+\z/, '') # Empty blank lines.

        # Find the longest common whitespace to all indented lines. Ignore lines
        # containing just -- or ++ as these seem to be used by comment authors
        # as delimeters.
        scanned_text = text.scan(/^[ \t]*(?!--\n|\+\+\n)(?=[^ \t\n])/)
        margin = scanned_text.inject do |current_margin, next_indent|
          if next_indent.start_with?(current_margin)
            current_margin
          elsif current_margin.start_with?(next_indent)
            next_indent
          else
            ''
          end
        end

        text.gsub(/^#{margin}/, ' ' * left_padding)
      end

      # Restrict a string to the given range of lines (1-indexed)
      # @param [String] content The string.
      # @param [Range, Integer] lines The line(s) to restrict it to.
      # @return [String] The resulting string.
      def restrict_to_lines(content, lines)
        line_range = one_index_range_or_number(lines)
        Array(content.lines.to_a[line_range]).join
      end

      def one_index_number(line_number)
        line_number > 0 ? line_number - 1 : line_number
      end

      # convert a 1-index range to a 0-indexed one
      def one_index_range(range)
        Range.new(one_index_number(range.begin), one_index_number(range.end))
      end

      def one_index_range_or_number(range_or_number)
        case range_or_number
        when Range
          one_index_range(range_or_number)
        else
          one_index_number(range_or_number)
        end
      end

      def absolute_index_number(line_number, array_length)
        if line_number >= 0
          line_number
        else
          [array_length + line_number, 0].max
        end
      end

      def absolute_index_range(range_or_number, array_length)
        case range_or_number
        when Range
          a = absolute_index_number(range_or_number.begin, array_length)
          b = absolute_index_number(range_or_number.end, array_length)
        else
          a = b = absolute_index_number(range_or_number, array_length)
        end

        Range.new(a, b)
      end

      def set_file_and_dir_locals(file_name, pry = pry_instance, ctx = target)
        return if !ctx || !file_name

        pry.last_file = File.expand_path(file_name)
        pry.inject_local("_file_", pry.last_file, ctx)

        pry.last_dir = File.dirname(pry.last_file)
        pry.inject_local("_dir_", pry.last_dir, ctx)
      end
    end
  end
end
