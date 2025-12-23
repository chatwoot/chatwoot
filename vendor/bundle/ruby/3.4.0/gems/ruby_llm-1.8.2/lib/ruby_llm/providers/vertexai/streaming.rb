# frozen_string_literal: true

module RubyLLM
  module Providers
    class VertexAI
      # Streaming methods for the Vertex AI implementation
      module Streaming
        def stream_url
          "projects/#{@config.vertexai_project_id}/locations/#{@config.vertexai_location}/publishers/google/models/#{@model}:streamGenerateContent?alt=sse" # rubocop:disable Layout/LineLength
        end
      end
    end
  end
end
