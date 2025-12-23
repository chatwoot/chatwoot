# frozen_string_literal: true

module RubyLLM
  module Providers
    class VertexAI
      # Chat methods for the Vertex AI implementation
      module Chat
        def completion_url
          "projects/#{@config.vertexai_project_id}/locations/#{@config.vertexai_location}/publishers/google/models/#{@model}:generateContent" # rubocop:disable Layout/LineLength
        end
      end
    end
  end
end
