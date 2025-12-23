# frozen_string_literal: true

module RubyLLM
  module Providers
    # OpenRouter API integration.
    class OpenRouter < OpenAI
      include OpenRouter::Models

      def api_base
        'https://openrouter.ai/api/v1'
      end

      def headers
        {
          'Authorization' => "Bearer #{@config.openrouter_api_key}"
        }
      end

      class << self
        def configuration_requirements
          %i[openrouter_api_key]
        end
      end
    end
  end
end
