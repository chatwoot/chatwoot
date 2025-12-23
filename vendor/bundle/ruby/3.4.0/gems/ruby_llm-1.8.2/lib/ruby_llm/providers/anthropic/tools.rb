# frozen_string_literal: true

module RubyLLM
  module Providers
    class Anthropic
      # Tools methods of the Anthropic API integration
      module Tools
        module_function

        def find_tool_uses(blocks)
          blocks.select { |c| c['type'] == 'tool_use' }
        end

        def format_tool_call(msg)
          content = []

          content << Media.format_text(msg.content) unless msg.content.nil? || msg.content.empty?

          msg.tool_calls.each_value do |tool_call|
            content << format_tool_use_block(tool_call)
          end

          {
            role: 'assistant',
            content:
          }
        end

        def format_tool_result(msg)
          {
            role: 'user',
            content: [format_tool_result_block(msg)]
          }
        end

        def format_tool_use_block(tool_call)
          {
            type: 'tool_use',
            id: tool_call.id,
            name: tool_call.name,
            input: tool_call.arguments
          }
        end

        def format_tool_result_block(msg)
          {
            type: 'tool_result',
            tool_use_id: msg.tool_call_id,
            content: Media.format_content(msg.content)
          }
        end

        def function_for(tool)
          {
            name: tool.name,
            description: tool.description,
            input_schema: {
              type: 'object',
              properties: clean_parameters(tool.parameters),
              required: required_parameters(tool.parameters)
            }
          }
        end

        def extract_tool_calls(data)
          if json_delta?(data)
            { nil => ToolCall.new(id: nil, name: nil, arguments: data.dig('delta', 'partial_json')) }
          else
            parse_tool_calls(data['content_block'])
          end
        end

        def parse_tool_calls(content_blocks)
          return nil if content_blocks.nil?

          content_blocks = [content_blocks] unless content_blocks.is_a?(Array)

          tool_calls = {}
          content_blocks.each do |block|
            next unless block && block['type'] == 'tool_use'

            tool_calls[block['id']] = ToolCall.new(
              id: block['id'],
              name: block['name'],
              arguments: block['input']
            )
          end

          tool_calls.empty? ? nil : tool_calls
        end

        def clean_parameters(parameters)
          parameters.transform_values do |param|
            {
              type: param.type,
              description: param.description
            }.compact
          end
        end

        def required_parameters(parameters)
          parameters.select { |_, param| param.required }.keys
        end
      end
    end
  end
end
