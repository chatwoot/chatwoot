# frozen_string_literal: true

module RuboCop
  module Cop
    # Help methods for determining if a line is too long.
    module LineLengthHelp
      include Alignment

      private

      def ignore_cop_directives?
        config.for_cop('Layout/LineLength')['IgnoreCopDirectives']
      end

      def directive_on_source_line?(line_index)
        source_line_number = line_index + processed_source.buffer.first_line
        comment = processed_source.comment_at_line(source_line_number)

        return false unless comment

        !!DirectiveComment.new(comment).match_captures
      end

      def allow_uri?
        config.for_cop('Layout/LineLength')['AllowURI']
      end

      def allowed_uri_position?(line, uri_range)
        uri_range.begin < max_line_length && uri_range.end == line_length(line)
      end

      def line_length(line)
        line.length + indentation_difference(line)
      end

      def find_excessive_uri_range(line)
        last_uri_match = match_uris(line).last
        return nil unless last_uri_match

        begin_position, end_position = last_uri_match.offset(0)
        end_position = extend_uri_end_position(line, end_position)

        line_indentation_difference = indentation_difference(line)
        begin_position += line_indentation_difference
        end_position += line_indentation_difference

        return nil if begin_position < max_line_length && end_position < max_line_length

        begin_position...end_position
      end

      def match_uris(string)
        matches = []
        string.scan(uri_regexp) do
          matches << $LAST_MATCH_INFO if valid_uri?($LAST_MATCH_INFO[0])
        end
        matches
      end

      def indentation_difference(line)
        return 0 unless tab_indentation_width

        index =
          if line.match?(/^[^\t]/)
            0
          else
            line.index(/[^\t]/) || 0
          end

        index * (tab_indentation_width - 1)
      end

      def extend_uri_end_position(line, end_position)
        # Extend the end position YARD comments with linked URLs of the form {<uri> <title>}
        if line&.match(/{(\s|\S)*}$/)
          match = line[end_position..line_length(line)]&.match(/(\s|\S)*}/)
          end_position += match.offset(0).last
        end

        # Extend the end position until the start of the next word, if any.
        # This allows for URIs that are wrapped in quotes or parens to be handled properly
        # while not allowing additional words to be added after the URL.
        if (match = line[end_position..line_length(line)]&.match(/^\S+(?=\s|$)/))
          end_position += match.offset(0).last
        end
        end_position
      end

      def tab_indentation_width
        config.for_cop('Layout/IndentationStyle')['IndentationWidth'] ||
          configured_indentation_width
      end

      def uri_regexp
        @uri_regexp ||= begin
          # Ruby 3.4 changes the default parser to RFC3986 which warns on make_regexp.
          # Additionally, the RFC2396_PARSER alias is only available on 3.4 for now.
          # Extra info at https://github.com/ruby/uri/issues/118
          parser = defined?(URI::RFC2396_PARSER) ? URI::RFC2396_PARSER : URI::DEFAULT_PARSER
          parser.make_regexp(config.for_cop('Layout/LineLength')['URISchemes'])
        end
      end

      def valid_uri?(uri_ish_string)
        URI.parse(uri_ish_string)
        true
      rescue URI::InvalidURIError, NoMethodError
        false
      end

      def line_length_without_directive(line)
        DirectiveComment.before_comment(line).rstrip.length
      end
    end
  end
end
