require 'openai'

module Captain
  module Llm
    class EmbeddingService
      DEFAULT_MODEL = 'text-embedding-3-small'.freeze

      def initialize(api_key: nil)
        @api_key = api_key || ENV.fetch('OPENAI_API_KEY', nil)
        @client = OpenAI::Client.new(access_token: @api_key, log_errors: Rails.env.development?)
      end

      def generate(text, model: DEFAULT_MODEL)
        response = @client.embeddings(
          parameters: {
            model: model,
            input: text
          }
        )

        extract_embedding(response)
      rescue StandardError => e
        Rails.logger.error("EmbeddingService Error: #{e.message}")
        raise e
      end

      # Alias for backward compatibility with existing code
      alias get_embedding generate

      private

      def extract_embedding(response)
        response.dig('data', 0, 'embedding') || []
      end
    end
  end
end
