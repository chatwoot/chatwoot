# frozen_string_literal: true

module RubyLLM
  # Identify potentially harmful content in text.
  # https://platform.openai.com/docs/guides/moderation
  class Moderation
    attr_reader :id, :model, :results

    def initialize(id:, model:, results:)
      @id = id
      @model = model
      @results = results
    end

    def self.moderate(input,
                      model: nil,
                      provider: nil,
                      assume_model_exists: false,
                      context: nil)
      config = context&.config || RubyLLM.config
      model ||= config.default_moderation_model || 'omni-moderation-latest'
      model, provider_instance = Models.resolve(model, provider: provider, assume_exists: assume_model_exists,
                                                       config: config)
      model_id = model.id

      provider_instance.moderate(input, model: model_id)
    end

    # Convenience method to get content from moderation result
    def content
      results
    end

    # Check if any content was flagged
    def flagged?
      results.any? { |result| result['flagged'] }
    end

    # Get all flagged categories across all results
    def flagged_categories
      results.flat_map do |result|
        result['categories']&.select { |_category, flagged| flagged }&.keys || []
      end.uniq
    end

    # Get category scores for the first result (most common case)
    def category_scores
      results.first&.dig('category_scores') || {}
    end

    # Get categories for the first result (most common case)
    def categories
      results.first&.dig('categories') || {}
    end
  end
end
