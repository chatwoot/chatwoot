# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module FileParser
      class AnnotationFinder
        COMPAT_PREFIX = "== Schema Info"
        COMPAT_PREFIX_MD = "## Schema Info"
        DEFAULT_ANNOTATION_ENDING = "#"

        class MalformedAnnotation < StandardError; end

        class NoAnnotationFound < StandardError; end

        # Returns the line index (not the line number) that the annotation starts.
        attr_reader :annotation_start
        # Returns the line index (not the line number) that the annotation ends, inclusive.
        attr_reader :annotation_end

        attr_reader :parser

        def initialize(content, wrapper_open, wrapper_close, parser)
          @content = content
          @wrapper_open = wrapper_open
          @wrapper_close = wrapper_close
          @annotation_start = nil
          @annotation_end = nil
          @parser = parser
        end

        # Find the annotation's line start and line end
        def run
          comments = @parser.comments

          start = comments.find_index { |comment, _| comment.include?(COMPAT_PREFIX) || comment.include?(COMPAT_PREFIX_MD) }
          raise NoAnnotationFound if start.nil? # Stop execution because we did not find

          if @wrapper_open
            prev_comment, _prev_line_number = comments[start - 1]

            # Change start to the line before if wrapper_open is defined and we find the wrapper open comment
            if prev_comment&.include?(@wrapper_open)
              start -= 1
            end
          end

          # Find a contiguous block of comments from the starting point
          ending = start
          while ending < comments.size - 1
            _comment, line_number = comments[ending]
            _next_comment, next_line_number = comments[ending + 1]

            if next_line_number - line_number == 1
              ending += 1
            else
              break
            end
          end

          raise MalformedAnnotation if start == ending

          if @wrapper_close
            if comments[ending].first.include?(@wrapper_close)
              # We can end here because it's the end of the annotation block
            else
              # Walk back until we find the end of the annotation comment block or the wrapper close to be flexible
              #  We check if @wrapper_close is a substring because `comments` contains strings with the comment character
              while ending > start && comments[ending].first != DEFAULT_ANNOTATION_ENDING && !comments[ending].first.include?(@wrapper_close)
                ending -= 1
              end
            end
          else
            # Walk back until we find the end of the annotation comment block
            while ending > start && comments[ending].first != DEFAULT_ANNOTATION_ENDING
              ending -= 1
            end
          end

          # We want .last because we want the line indexes
          @annotation_start = comments[start].last
          @annotation_end = comments[ending].last

          [@annotation_start, @annotation_end]
        end

        def annotation
          @annotation ||=
            begin
              lines = @content.lines
              lines[@annotation_start..@annotation_end].join
            end
        end

        # Returns true if annotations are detected in the file content
        def annotated?
          @annotation_start && @annotation_end
        end
      end
    end
  end
end
