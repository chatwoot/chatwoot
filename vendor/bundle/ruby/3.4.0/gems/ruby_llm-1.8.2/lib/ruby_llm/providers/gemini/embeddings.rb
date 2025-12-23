# frozen_string_literal: true

module RubyLLM
  module Providers
    class Gemini
      # Embeddings methods for the Gemini API integration
      module Embeddings
        module_function

        def embedding_url(model:)
          "models/#{model}:batchEmbedContents"
        end

        def render_embedding_payload(text, model:, dimensions:)
          { requests: [text].flatten.map { |t| single_embedding_payload(t, model:, dimensions:) } }
        end

        def parse_embedding_response(response, model:, text:)
          vectors = response.body['embeddings']&.map { |e| e['values'] }
          vectors = vectors.first if vectors&.length == 1 && !text.is_a?(Array)

          Embedding.new(vectors:, model:, input_tokens: 0)
        end

        private

        def single_embedding_payload(text, model:, dimensions:)
          {
            model: "models/#{model}",
            content: { parts: [{ text: text.to_s }] },
            outputDimensionality: dimensions
          }.compact
        end
      end
    end
  end
end
