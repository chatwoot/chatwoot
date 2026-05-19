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
      openai_only_api_key.presence || system_openai_api_key
    end

    private

    def openai_only_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_EMBEDDING_API_KEY')&.value
    end

    def system_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def system_openai_api_key
      system_api_key if Llm::Config.default_openai_endpoint?
    end
  end
end
