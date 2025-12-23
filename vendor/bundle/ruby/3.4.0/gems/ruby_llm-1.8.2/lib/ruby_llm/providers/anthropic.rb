# frozen_string_literal: true

module RubyLLM
  module Providers
    # Anthropic Claude API integration.
    class Anthropic < Provider
      include Anthropic::Chat
      include Anthropic::Embeddings
      include Anthropic::Media
      include Anthropic::Models
      include Anthropic::Streaming
      include Anthropic::Tools

      def api_base
        'https://api.anthropic.com'
      end

      def headers
        {
          'x-api-key' => @config.anthropic_api_key,
          'anthropic-version' => '2023-06-01'
        }
      end

      class << self
        def capabilities
          Anthropic::Capabilities
        end

        def configuration_requirements
          %i[anthropic_api_key]
        end
      end
    end
  end
end
