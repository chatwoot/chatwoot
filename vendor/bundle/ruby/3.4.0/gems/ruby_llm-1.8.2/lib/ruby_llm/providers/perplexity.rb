# frozen_string_literal: true

module RubyLLM
  module Providers
    # Perplexity API integration.
    class Perplexity < OpenAI
      include Perplexity::Chat
      include Perplexity::Models

      def api_base
        'https://api.perplexity.ai'
      end

      def headers
        {
          'Authorization' => "Bearer #{@config.perplexity_api_key}",
          'Content-Type' => 'application/json'
        }
      end

      class << self
        def capabilities
          Perplexity::Capabilities
        end

        def configuration_requirements
          %i[perplexity_api_key]
        end
      end

      def parse_error(response)
        body = response.body
        return if body.empty?

        # If response is HTML (Perplexity returns HTML for auth errors)
        if body.include?('<html>') && body.include?('<title>')
          title_match = body.match(%r{<title>(.+?)</title>})
          if title_match
            message = title_match[1]
            message = message.sub(/^\d+\s+/, '')
            return message
          end
        end
        super
      end
    end
  end
end
