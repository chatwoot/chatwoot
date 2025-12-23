# frozen_string_literal: true

module RubyLLM
  # Global configuration for RubyLLM
  class Configuration
    attr_accessor :openai_api_key,
                  :openai_api_base,
                  :openai_organization_id,
                  :openai_project_id,
                  :openai_use_system_role,
                  :anthropic_api_key,
                  :gemini_api_key,
                  :vertexai_project_id,
                  :vertexai_location,
                  :deepseek_api_key,
                  :perplexity_api_key,
                  :bedrock_api_key,
                  :bedrock_secret_key,
                  :bedrock_region,
                  :bedrock_session_token,
                  :openrouter_api_key,
                  :ollama_api_base,
                  :gpustack_api_base,
                  :gpustack_api_key,
                  :mistral_api_key,
                  # Default models
                  :default_model,
                  :default_embedding_model,
                  :default_moderation_model,
                  :default_image_model,
                  # Model registry
                  :model_registry_class,
                  # Rails integration
                  :use_new_acts_as,
                  # Connection configuration
                  :request_timeout,
                  :max_retries,
                  :retry_interval,
                  :retry_backoff_factor,
                  :retry_interval_randomness,
                  :http_proxy,
                  # Logging configuration
                  :logger,
                  :log_file,
                  :log_level,
                  :log_stream_debug

    def initialize
      @request_timeout = 120
      @max_retries = 3
      @retry_interval = 0.1
      @retry_backoff_factor = 2
      @retry_interval_randomness = 0.5
      @http_proxy = nil

      @default_model = 'gpt-4.1-nano'
      @default_embedding_model = 'text-embedding-3-small'
      @default_moderation_model = 'omni-moderation-latest'
      @default_image_model = 'gpt-image-1'

      @model_registry_class = 'Model'
      @use_new_acts_as = false

      @log_file = $stdout
      @log_level = ENV['RUBYLLM_DEBUG'] ? Logger::DEBUG : Logger::INFO
      @log_stream_debug = ENV['RUBYLLM_STREAM_DEBUG'] == 'true'
    end

    def instance_variables
      super.reject { |ivar| ivar.to_s.match?(/_id|_key|_secret|_token$/) }
    end
  end
end
