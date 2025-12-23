# frozen_string_literal: true

module RuboCop
  # Common functionality for finding names that are similar to a given name.
  # @api private
  module NameSimilarity
    module_function

    def find_similar_name(target_name, names)
      similar_names = find_similar_names(target_name, names)

      similar_names.first
    end

    def find_similar_names(target_name, names)
      # DidYouMean::SpellChecker is not available in all versions of Ruby, and
      # even on versions where it *is* available (>= 2.3), it is not always
      # required correctly. So we do a feature check first.
      # See: https://github.com/rubocop/rubocop/issues/7979
      return [] unless defined?(DidYouMean::SpellChecker)

      names = names.dup
      names.delete(target_name)

      spell_checker = DidYouMean::SpellChecker.new(dictionary: names)
      spell_checker.correct(target_name)
    end
  end
end
