# frozen_string_literal: true

module RubyLLM
  module Providers
    # GPUStack API integration based on Ollama.
    class GPUStack < OpenAI
      include GPUStack::Chat
      include GPUStack::Models
      include GPUStack::Media

      def api_base
        @config.gpustack_api_base
      end

      def headers
        return {} unless @config.gpustack_api_key

        {
          'Authorization' => "Bearer #{@config.gpustack_api_key}"
        }
      end

      class << self
        def local?
          true
        end

        def configuration_requirements
          %i[gpustack_api_base]
        end
      end
    end
  end
end
