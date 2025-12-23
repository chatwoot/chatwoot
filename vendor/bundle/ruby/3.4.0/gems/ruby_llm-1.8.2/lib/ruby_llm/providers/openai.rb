# frozen_string_literal: true

module RubyLLM
  module Providers
    # OpenAI API integration.
    class OpenAI < Provider
      include OpenAI::Chat
      include OpenAI::Embeddings
      include OpenAI::Models
      include OpenAI::Moderation
      include OpenAI::Streaming
      include OpenAI::Tools
      include OpenAI::Images
      include OpenAI::Media

      def api_base
        @config.openai_api_base || 'https://api.openai.com/v1'
      end

      def headers
        {
          'Authorization' => "Bearer #{@config.openai_api_key}",
          'OpenAI-Organization' => @config.openai_organization_id,
          'OpenAI-Project' => @config.openai_project_id
        }.compact
      end

      def maybe_normalize_temperature(temperature, model)
        OpenAI::Capabilities.normalize_temperature(temperature, model.id)
      end

      class << self
        def capabilities
          OpenAI::Capabilities
        end

        def configuration_requirements
          %i[openai_api_key]
        end
      end
    end
  end
end
