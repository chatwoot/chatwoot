module Llm::OpenAiConfig
  class << self
    def api_base
      "#{LlmConstants::OPENAI_API_ENDPOINT}/"
    end

    def api_v1_base
      "#{LlmConstants::OPENAI_API_ENDPOINT}/v1"
    end

    def chat_completions_url
      "#{api_v1_base}/chat/completions"
    end

    def api_key
      openai_only_api_key
    end

    def embedding_model
      InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_MODEL')&.value.presence || LlmConstants::DEFAULT_EMBEDDING_MODEL
    end

    private

    def openai_only_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_API_KEY')&.value
    end
  end
end
