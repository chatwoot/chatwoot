# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module AnnotatedFile
      # Generates the file with fresh annotations
      class Generator
        def initialize(file_content, new_annotations, annotation_position, parser_klass, parsed_file, options)
          @annotation_position = annotation_position
          @options = options

          @new_wrapped_annotations = wrapped_content(new_annotations)

          @new_annotations = new_annotations
          @file_content = file_content

          @parser = parser_klass
          @parsed_file = parsed_file
        end

        # @return [String] Returns the annotated file content to be written back to a file
        def generate
          # Need to keep `.to_s` for now since the it can be either a String or Symbol
          annotation_write_position = @options[@annotation_position].to_s

          # New method: first remove annotations
          content_without_annotations = if @parsed_file.has_annotations?
            @file_content.sub(@parsed_file.annotations_with_whitespace, "")
          elsif @options[:force]
            @file_content.sub(@parsed_file.annotations_with_whitespace, "")
          else
            @file_content
          end

          # We need to get class start and class end depending on the position
          parsed = @parser.parse(content_without_annotations)

          _content = if %w[after bottom].include?(annotation_write_position)
            content_annotated_after(parsed, content_without_annotations)
          else
            content_annotated_before(parsed, content_without_annotations, annotation_write_position)
          end
        end

        private

        def content_annotated_before(parsed, content_without_annotations, write_position)
          same_write_position = @parsed_file.has_annotations? && @parsed_file.annotation_position.to_s == write_position

          _constant_name, line_number_before = determine_annotation_position(parsed)

          content_with_annotations_written_before = []
          content_with_annotations_written_before << content_without_annotations.lines[0...line_number_before]
          content_with_annotations_written_before << $/ if @parsed_file.has_leading_whitespace? && same_write_position
          content_with_annotations_written_before << formatted_annotations(content_without_annotations, line_number_before)
          content_with_annotations_written_before << $/ if @parsed_file.has_trailing_whitespace? && same_write_position
          content_with_annotations_written_before << content_without_annotations.lines[line_number_before..]

          content_with_annotations_written_before.join
        end

        # Determines where to place the annotation based on the nested_position option.
        # When nested_position is enabled, finds the most deeply nested class declaration
        # to place annotations directly above nested classes instead of at the file top.
        def determine_annotation_position(parsed)
          # Handle empty files where no classes/modules are found
          return [nil, 0] if parsed.starts.empty?

          return parsed.starts.first unless @options[:nested_position]

          class_entries = parsed.starts.select { |name, _line| parsed.type_map[name] == :class }
          class_entries.last || parsed.starts.first
        end

        # Formats annotations with appropriate indentation for consistent code structure.
        # Applies the same indentation level as the target line to maintain proper
        # code alignment when using nested positioning.
        def formatted_annotations(content_without_annotations, line_number_before)
          indentation = determine_indentation(content_without_annotations, line_number_before)
          @new_wrapped_annotations.lines.map { |line| "#{indentation}#{line}" }
        end

        # Calculates the indentation string to apply to annotations for nested positioning.
        # Extracts leading whitespace from the target line to preserve visual hierarchy
        # and readability of nested code structures.
        def determine_indentation(content_without_annotations, line_number_before)
          return "" unless @options[:nested_position] && line_number_before > 0

          target_line = content_without_annotations.lines[line_number_before]
          target_line&.match(/^(\s*)/)&.[](1) || ""
        end

        def content_annotated_after(parsed, content_without_annotations)
          _constant_name, line_number_after = parsed.ends.last

          # Handle empty files where no classes/modules are found
          if line_number_after.nil?
            content_lines = content_without_annotations.lines
            # For empty files, append annotations at the end
            content_with_annotations_written_after = []
            content_with_annotations_written_after << content_lines
            content_with_annotations_written_after << $/ unless content_lines.empty?
            content_with_annotations_written_after << @new_wrapped_annotations.lines
            return content_with_annotations_written_after.join
          end

          content_with_annotations_written_after = []
          content_with_annotations_written_after << content_without_annotations.lines[0..line_number_after]
          content_with_annotations_written_after << $/
          content_with_annotations_written_after << @new_wrapped_annotations.lines
          content_with_annotations_written_after << content_without_annotations.lines[(line_number_after + 1)..]

          content_with_annotations_written_after.join
        end

        def wrapped_content(content)
          wrapper_open = if @options[:wrapper_open]
            "# #{@options[:wrapper_open]}\n"
          else
            ""
          end

          wrapper_close = if @options[:wrapper_close]
            "# #{@options[:wrapper_close]}\n"
          else
            ""
          end

          _wrapped_info_block = "#{wrapper_open}#{content}#{wrapper_close}"
        end
      end
    end
  end
end
