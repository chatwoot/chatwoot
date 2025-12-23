# frozen_string_literal: true

module RubyLLM
  module Providers
    class Anthropic
      # Embeddings methods of the Anthropic API integration
      module Embeddings
        private

        def embed
          raise Error "Anthropic doesn't support embeddings"
        end

        alias render_embedding_payload embed
        alias embedding_url embed
        alias parse_embedding_response embed
      end
    end
  end
end
