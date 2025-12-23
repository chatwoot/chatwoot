# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module FileParser
      class ParsedFile
        SKIP_ANNOTATION_STRING = "# -*- SkipSchemaAnnotations"

        def initialize(file_content, new_annotations, parser_klass, options)
          @file_content = file_content
          @file_lines = @file_content.lines
          @new_annotations = new_annotations
          @parser_klass = parser_klass
          @options = options
        end

        def parse
          @file_parser = @parser_klass.parse(@file_content)
          @finder = AnnotationFinder.new(@file_content, @options[:wrapper_open], @options[:wrapper_close], @file_parser)
          has_annotations = false

          begin
            @finder.run
            has_annotations = @finder.annotated?
          rescue AnnotationFinder::NoAnnotationFound => _e
          end

          annotations = if has_annotations
            @file_lines[(@finder.annotation_start)..(@finder.annotation_end)].join
          else
            ""
          end

          @diff = AnnotationDiffGenerator.new(annotations, @new_annotations).generate

          has_skip_string = @file_parser.comments.any? { |comment, _lineno| comment.include?(SKIP_ANNOTATION_STRING) }
          annotations_changed = @diff.changed?

          has_leading_whitespace = false
          has_trailing_whitespace = false

          annotations_with_whitespace = if has_annotations
            begin
              annotation_start = @finder.annotation_start
              annotation_end = @finder.annotation_end

              if @file_lines[annotation_start - 1]&.strip&.empty?
                annotation_start -= 1
                has_leading_whitespace = true
              end

              if @file_lines[annotation_end + 1]&.strip&.empty?
                annotation_end += 1
                has_trailing_whitespace = true
              end

              @file_lines[annotation_start..annotation_end].join
            end
          else
            ""
          end

          # :before or :after when it's set
          annotation_position = nil

          if has_annotations
            const_declaration = @file_parser.starts.first

            # If the file does not have any class or module declaration then const_declaration can be nil
            _const, line_number = const_declaration

            if line_number
              annotation_position = if @finder.annotation_start < line_number
                :before
              else
                :after
              end
            end
          end

          _result = ParsedFileResult.new(
            has_annotations: has_annotations,
            has_skip_string: has_skip_string,
            annotations_changed: annotations_changed,
            annotations: annotations,
            annotations_with_whitespace: annotations_with_whitespace,
            has_leading_whitespace: has_leading_whitespace,
            has_trailing_whitespace: has_trailing_whitespace,
            annotation_position: annotation_position,
            starts: @file_parser.starts,
            ends: @file_parser.ends
          )
        end
      end
    end
  end
end
