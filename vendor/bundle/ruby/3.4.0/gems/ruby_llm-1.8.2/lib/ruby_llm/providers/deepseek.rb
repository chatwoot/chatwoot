# frozen_string_literal: true

module RubyLLM
  module Providers
    # DeepSeek API integration.
    class DeepSeek < OpenAI
      include DeepSeek::Chat

      def api_base
        'https://api.deepseek.com'
      end

      def headers
        {
          'Authorization' => "Bearer #{@config.deepseek_api_key}"
        }
      end

      class << self
        def capabilities
          DeepSeek::Capabilities
        end

        def configuration_requirements
          %i[deepseek_api_key]
        end
      end
    end
  end
end
