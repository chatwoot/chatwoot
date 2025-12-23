# frozen_string_literal: true

module RuboCop
  module Cop
    # Representation of an annotation comment in source code (eg. `# TODO: blah blah blah`).
    class AnnotationComment
      attr_reader :comment, :margin, :keyword, :colon, :space, :note

      # @param [Parser::Source::Comment] comment
      # @param [Array<String>] keywords
      def initialize(comment, keywords)
        @comment = comment
        @keywords = keywords
        @margin, @keyword, @colon, @space, @note = split_comment(comment)
      end

      def annotation?
        keyword_appearance? && !just_keyword_of_sentence?
      end

      def correct?(colon:)
        return false unless keyword && space && note
        return false unless keyword == keyword.upcase

        self.colon.nil? == !colon
      end

      # Returns the range bounds for just the annotation
      def bounds
        start = comment.source_range.begin_pos + margin.length
        length = [keyword, colon, space].reduce(0) { |len, elem| len + elem.to_s.length }
        [start, start + length]
      end

      private

      attr_reader :keywords

      def split_comment(comment)
        # Sort keywords by reverse length so that if a keyword is in a phrase
        # but also on its own, both will match properly.
        match = comment.text.match(regex)
        return false unless match

        match.captures
      end

      KEYWORDS_REGEX_CACHE = {} # rubocop:disable Style/MutableConstant
      private_constant :KEYWORDS_REGEX_CACHE

      def regex
        KEYWORDS_REGEX_CACHE[keywords] ||= begin
          keywords_regex = Regexp.new(
            Regexp.union(keywords.sort_by { |w| -w.length }).source,
            Regexp::IGNORECASE
          )
          /^(# ?)(\b#{keywords_regex}\b)(\s*:)?(\s+)?(\S+)?/i
        end
      end

      def keyword_appearance?
        keyword && (colon || space)
      end

      def just_keyword_of_sentence?
        keyword == keyword.capitalize && !colon && space && note
      end
    end
  end
end
