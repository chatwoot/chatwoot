# frozen_string_literal: true

module Aloo
  module ContextBudget
    extend ActiveSupport::Concern

    # Token budgets to prevent context overflow
    KNOWLEDGE_CONTEXT_TOKENS = 2000
    MEMORY_CONTEXT_TOKENS = 1000
    CONVERSATION_HISTORY_TOKENS = 1000
    TOTAL_CONTEXT_BUDGET = 4000

    # Approximate chars per token (conservative estimate)
    # GPT-4/Claude average ~4 chars per token for English
    CHARS_PER_TOKEN = 4

    class_methods do
      # Truncate text to fit within token budget
      def truncate_to_budget(text, max_tokens)
        return '' if text.blank?

        max_chars = max_tokens * CHARS_PER_TOKEN
        return text if text.length <= max_chars

        # Truncate at paragraph boundary if possible
        truncated = text.truncate(max_chars, separator: "\n\n", omission: "\n\n[truncated]")

        # If no paragraph boundary found, truncate at sentence
        if truncated == text.truncate(max_chars, omission: '')
          truncated = text.truncate(max_chars, separator: '. ', omission: '... [truncated]')
        end

        truncated
      end

      # Estimate token count for text
      def estimate_tokens(text)
        return 0 if text.blank?

        (text.length.to_f / CHARS_PER_TOKEN).ceil
      end

      # Check if text exceeds budget
      def exceeds_budget?(text, max_tokens)
        estimate_tokens(text) > max_tokens
      end
    end

    # Instance methods delegate to class methods
    def truncate_to_budget(text, max_tokens)
      self.class.truncate_to_budget(text, max_tokens)
    end

    def estimate_tokens(text)
      self.class.estimate_tokens(text)
    end
  end
end
