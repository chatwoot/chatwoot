# frozen_string_literal: true

class Pry
  class Command
    class CodeCollector
      include Helpers::CommandHelpers

      attr_reader :args
      attr_reader :opts
      attr_reader :pry_instance

      # The name of the explicitly given file (if any).
      attr_accessor :file

      class << self
        attr_accessor :input_expression_ranges
        attr_accessor :output_result_ranges
      end

      @input_expression_ranges = []
      @output_result_ranges = []

      def initialize(args, opts, pry_instance)
        @args = args
        @opts = opts
        @pry_instance = pry_instance
      end

      # Add the `--lines`, `-o`, `-i`, `-s`, `-d` options.
      def self.inject_options(opt)
        @input_expression_ranges = []
        @output_result_ranges = []

        opt.on :l, :lines, "Restrict to a subset of lines. Takes a line number " \
                           "or range",
               optional_argument: true, as: Range, default: 1..-1
        opt.on :o, :out, "Select lines from Pry's output result history. " \
                         "Takes an index or range",
               optional_argument: true, as: Range, default: -5..-1 do |r|
          output_result_ranges << (r || (-5..-1))
        end
        opt.on :i, :in, "Select lines from Pry's input expression history. " \
                        "Takes an index or range",
               optional_argument: true, as: Range, default: -5..-1 do |r|
          input_expression_ranges << (r || (-5..-1))
        end
        opt.on :s, :super, "Select the 'super' method. Can be repeated to " \
                           "traverse the ancestors",
               as: :count
        opt.on :d, :doc, "Select lines from the code object's documentation"
      end

      # The content (i.e code/docs) for the selected object.
      # If the user provided a bare code object, it returns the source.
      # If the user provided the `-i` or `-o` switches, it returns the
      # selected input/output lines joined as a string. If the user used
      # `-d CODE_OBJECT` it returns the docs for that code object.
      #
      # @return [String]
      def content
        @content ||=
          begin
            if bad_option_combination?
              raise CommandError,
                    "Only one of --out, --in, --doc and CODE_OBJECT may " \
                    "be specified."
            end

            content = if opts.present?(:o)
                        pry_output_content
                      elsif opts.present?(:i)
                        pry_input_content
                      elsif opts.present?(:d)
                        code_object_doc
                      else
                        code_object_source_or_file
                      end

            restrict_to_lines(content, line_range)
          end
      end

      # The code object
      #
      # @return [Pry::WrappedModule, Pry::Method, Pry::Command]
      def code_object
        Pry::CodeObject.lookup(obj_name, pry_instance, super: opts[:super])
      end

      # Given a string and a range, return the `range` lines of that
      # string.
      #
      # @param [String] content
      # @param [Range, Fixnum] range
      # @return [String] The string restricted to the given range
      def restrict_to_lines(content, range)
        Array(content.lines.to_a[range]).join
      end

      # The selected `pry_instance.output_ring` as a string, as specified by
      # the `-o` switch.
      #
      # @return [String]
      def pry_output_content
        pry_array_content_as_string(
          pry_instance.output_ring,
          self.class.output_result_ranges,
          &:pretty_inspect
        )
      end

      # The selected `pry_instance.input_ring` as a string, as specified by
      # the `-i` switch.
      #
      # @return [String]
      def pry_input_content
        pry_array_content_as_string(
          pry_instance.input_ring, self.class.input_expression_ranges
        ) { |v| v }
      end

      # The line range passed to `--lines`, converted to a 0-indexed range.
      def line_range
        opts.present?(:lines) ? one_index_range_or_number(opts[:lines]) : 0..-1
      end

      # Name of the object argument
      def obj_name
        @obj_name ||= args.empty? ? "" : args.join(" ")
      end

      private

      def bad_option_combination?
        [opts.present?(:in), opts.present?(:out),
         !args.empty?].count(true) > 1
      end

      def pry_array_content_as_string(array, ranges)
        all = ''
        ranges.each do |range|
          if convert_to_range(range).first == 0
            raise CommandError, "Minimum value for range is 1, not 0."
          end

          ranged_array = Array(array[range]) || []
          ranged_array.compact.each { |v| all += yield(v) }
        end

        all
      end

      def code_object_doc
        (code_object && code_object.doc) || could_not_locate(obj_name)
      end

      def code_object_source_or_file
        (code_object && code_object.source) || file_content
      end

      def file_content
        if File.exist?(obj_name)
          # Set the file accessor.
          self.file = obj_name
          File.read(obj_name)
        else
          could_not_locate(obj_name)
        end
      end

      def could_not_locate(name)
        raise CommandError, "Cannot locate: #{name}!"
      end

      def convert_to_range(range)
        return range if range.is_a?(Range)

        (range..range)
      end
    end
  end
end
