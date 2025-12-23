# frozen_string_literal: true

module RubyLLM
  module Providers
    class Anthropic
      # Streaming methods of the Anthropic API integration
      module Streaming
        private

        def stream_url
          completion_url
        end

        def build_chunk(data)
          Chunk.new(
            role: :assistant,
            model_id: extract_model_id(data),
            content: data.dig('delta', 'text'),
            input_tokens: extract_input_tokens(data),
            output_tokens: extract_output_tokens(data),
            tool_calls: extract_tool_calls(data)
          )
        end

        def json_delta?(data)
          data['type'] == 'content_block_delta' && data.dig('delta', 'type') == 'input_json_delta'
        end

        def parse_streaming_error(data)
          error_data = JSON.parse(data)
          return unless error_data['type'] == 'error'

          case error_data.dig('error', 'type')
          when 'overloaded_error'
            [529, error_data['error']['message']]
          else
            [500, error_data['error']['message']]
          end
        end
      end
    end
  end
end
