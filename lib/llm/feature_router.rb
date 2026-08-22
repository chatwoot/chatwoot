module Llm::FeatureRouter
  class UnknownFeatureError < StandardError; end

  FEATURE_KEYS = %w[
    conversation_completion
    editor
    assistant
    copilot
    label_suggestion
    document_faq_generation
    conversation_faq_generation
    conversation_faq_matching
    pdf_faq_generation
    help_center_article_generation
    onboarding_content_generation
    help_center_query_translation
    audio_transcription
    help_center_search
  ].freeze

  class << self
    def resolve(feature:, account: nil)
      feature_key = feature.to_s
      raise UnknownFeatureError, "Unknown LLM feature: #{feature_key}" unless FEATURE_KEYS.include?(feature_key)

      model = Llm::Config.model

      {
        feature: feature_key,
        provider: Llm::Config.provider_for(model),
        model: model,
        source: :default
      }
    end

    def feature_keys
      FEATURE_KEYS.reject { |key| key == 'conversation_completion' }
    end

    def feature?(feature)
      FEATURE_KEYS.include?(feature.to_s)
    end
  end
end
