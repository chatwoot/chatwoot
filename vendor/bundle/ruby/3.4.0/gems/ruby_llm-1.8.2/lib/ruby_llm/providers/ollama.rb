# frozen_string_literal: true

module RubyLLM
  module Providers
    # Ollama API integration.
    class Ollama < OpenAI
      include Ollama::Chat
      include Ollama::Media
      include Ollama::Models

      def api_base
        @config.ollama_api_base
      end

      def headers
        {}
      end

      class << self
        def configuration_requirements
          %i[ollama_api_base]
        end

        def local?
          true
        end
      end
    end
  end
end
