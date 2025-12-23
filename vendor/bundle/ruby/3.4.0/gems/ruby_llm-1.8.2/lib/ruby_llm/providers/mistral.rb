# frozen_string_literal: true

module RubyLLM
  module Providers
    # Mistral API integration.
    class Mistral < OpenAI
      include Mistral::Chat
      include Mistral::Models
      include Mistral::Embeddings

      def api_base
        'https://api.mistral.ai/v1'
      end

      def headers
        {
          'Authorization' => "Bearer #{@config.mistral_api_key}"
        }
      end

      class << self
        def capabilities
          Mistral::Capabilities
        end

        def configuration_requirements
          %i[mistral_api_key]
        end
      end
    end
  end
end
