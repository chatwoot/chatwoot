# frozen_string_literal: true

module RubyLLM
  module Providers
    # Native Gemini API implementation
    class Gemini < Provider
      include Gemini::Chat
      include Gemini::Embeddings
      include Gemini::Images
      include Gemini::Models
      include Gemini::Streaming
      include Gemini::Tools
      include Gemini::Media

      def api_base
        'https://generativelanguage.googleapis.com/v1beta'
      end

      def headers
        {
          'x-goog-api-key' => @config.gemini_api_key
        }
      end

      class << self
        def capabilities
          Gemini::Capabilities
        end

        def configuration_requirements
          %i[gemini_api_key]
        end
      end
    end
  end
end
