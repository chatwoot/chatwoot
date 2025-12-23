# frozen_string_literal: true

module RubyLLM
  module Providers
    class Bedrock
      module Streaming
        # Module for handling content extraction from AWS Bedrock streaming responses.
        module ContentExtraction
          def json_delta?(data)
            data['type'] == 'content_block_delta' && data.dig('delta', 'type') == 'input_json_delta'
          end

          def extract_streaming_content(data)
            return '' unless data.is_a?(Hash)

            extract_content_by_type(data)
          end

          def extract_tool_calls(data)
            data.dig('message', 'tool_calls') || data['tool_calls']
          end

          def extract_model_id(data)
            data.dig('message', 'model') || @model_id
          end

          def extract_input_tokens(data)
            data.dig('message', 'usage', 'input_tokens')
          end

          def extract_output_tokens(data)
            data.dig('message', 'usage', 'output_tokens') || data.dig('usage', 'output_tokens')
          end

          private

          def extract_content_by_type(data)
            case data['type']
            when 'content_block_start' then extract_block_start_content(data)
            when 'content_block_delta' then extract_delta_content(data)
            else ''
            end
          end

          def extract_block_start_content(data)
            data.dig('content_block', 'text').to_s
          end

          def extract_delta_content(data)
            data.dig('delta', 'text').to_s
          end
        end
      end
    end
  end
end
