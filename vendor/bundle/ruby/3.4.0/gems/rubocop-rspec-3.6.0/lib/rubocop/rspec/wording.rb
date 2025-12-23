# frozen_string_literal: true

module RuboCop
  module RSpec
    # RSpec example wording rewriter
    class Wording
      SHOULDNT_PREFIX    = /\Ashould(?:n't|n’t| not)\b/i.freeze
      SHOULDNT_BE_PREFIX = /#{SHOULDNT_PREFIX} be\b/i.freeze
      WILL_NOT_PREFIX    = /\Awill not\b/i.freeze
      WONT_PREFIX        = /\Awo(?:n't|n’t)\b/i.freeze
      ES_SUFFIX_PATTERN  = /(?:o|s|x|ch|sh|z)\z/i.freeze
      IES_SUFFIX_PATTERN = /[^aeou]y\z/i.freeze

      def initialize(text, ignore:, replace:)
        @text         = text
        @ignores      = ignore
        @replacements = replace
      end

      def rewrite
        case text
        when SHOULDNT_BE_PREFIX
          replace_prefix(SHOULDNT_BE_PREFIX, 'is not')
        when SHOULDNT_PREFIX
          replace_prefix(SHOULDNT_PREFIX, 'does not')
        when WILL_NOT_PREFIX
          replace_prefix(WILL_NOT_PREFIX, 'does not')
        when WONT_PREFIX
          replace_prefix(WONT_PREFIX, 'does not')
        else
          remove_should_and_pluralize
        end
      end

      private

      attr_reader :text, :ignores, :replacements

      def replace_prefix(pattern, replacement)
        text.sub(pattern) do |matched|
          uppercase?(matched) ? replacement.upcase : replacement
        end
      end

      def uppercase?(word)
        word.upcase.eql?(word)
      end

      def remove_should_and_pluralize
        _should, *words = text.split

        words.each_with_index do |word, index|
          next if ignored_word?(word)

          words[index] = substitute(word)

          break
        end

        words.join(' ')
      end

      def ignored_word?(word)
        ignores.any? { |ignore| ignore.casecmp(word).zero? }
      end

      def substitute(word)
        # NOTE: Custom replacements are case sensitive.
        return replacements.fetch(word) if replacements.key?(word)

        case word
        when ES_SUFFIX_PATTERN  then append_suffix(word, 'es')
        when IES_SUFFIX_PATTERN then append_suffix(word[0..-2], 'ies')
        else append_suffix(word, 's')
        end
      end

      def append_suffix(word, suffix)
        suffix = suffix.upcase if uppercase?(word)

        "#{word}#{suffix}"
      end

      private_constant(*constants(false))
    end
  end
end
