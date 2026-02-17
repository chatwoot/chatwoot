require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4.1-mini'.freeze
  REGISTRY_TTL = 1.hour
  REGISTRY_PATH = Rails.root.join('tmp/ruby_llm_models.json').to_s

  class << self
    def initialized?
      @initialized ||= false
    end

    def initialize!
      return if @initialized

      configure_ruby_llm
      refresh_model_registry
      @initialized = true
    end

    def reset!
      @initialized = false
    end

    def with_api_key(api_key, api_base: nil)
      context = RubyLLM.context do |config|
        config.openai_api_key = api_key
        config.openai_api_base = api_base
      end

      yield context
    end

    private

    def refresh_model_registry
      if fresh_registry_file?
        RubyLLM.models.load_from_json!(REGISTRY_PATH)
      else
        RubyLLM.models.refresh!
        RubyLLM.models.save_to_json(REGISTRY_PATH)
      end
    rescue StandardError => e
      Rails.logger.warn "Failed to refresh RubyLLM model registry: #{e.message}"
    end

    def fresh_registry_file?
      File.exist?(REGISTRY_PATH) && File.mtime(REGISTRY_PATH) > REGISTRY_TTL.ago
    end

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        config.openai_api_base = openai_endpoint.chomp('/') if openai_endpoint.present?
        config.logger = Rails.logger
      end
    end

    def system_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end
  end
end
