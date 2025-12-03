# frozen_string_literal: true

module Captain
  module Providers
    # Factory for creating LLM provider instances
    # Automatically selects the correct provider based on configuration
    class Factory
      class << self
        # Create a provider instance based on configuration
        # @param config [Hash, nil] Optional configuration hash. If nil, uses Captain::Config.current_config
        # @return [Captain::Service] Provider instance (OpenaiProvider or GeminiProvider)
        # @raise [ArgumentError] If provider is unknown
        def create(config = nil)
          config ||= Captain::Config.current_config

          case config[:provider]
          when 'openai'
            OpenaiProvider.new(config)
          when 'gemini'
            GeminiProvider.new(config)
          else
            raise ArgumentError, "Unknown provider: #{config[:provider]}. Supported: openai, gemini"
          end
        end
      end
    end
  end
end
