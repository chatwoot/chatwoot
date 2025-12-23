# frozen_string_literal: true

module RubyLLM
  module Providers
    class OpenAI
      # Chat methods of the OpenAI API integration
      module Chat
        def completion_url
          'chat/completions'
        end

        module_function

        def render_payload(messages, tools:, temperature:, model:, stream: false, schema: nil) # rubocop:disable Metrics/ParameterLists
          payload = {
            model: model.id,
            messages: format_messages(messages),
            stream: stream
          }

          payload[:temperature] = temperature unless temperature.nil?
          payload[:tools] = tools.map { |_, tool| tool_for(tool) } if tools.any?

          if schema
            strict = schema[:strict] != false

            payload[:response_format] = {
              type: 'json_schema',
              json_schema: {
                name: 'response',
                schema: schema,
                strict: strict
              }
            }
          end

          payload[:stream_options] = { include_usage: true } if stream
          payload
        end

        def parse_completion_response(response)
          data = response.body
          return if data.empty?

          raise Error.new(response, data.dig('error', 'message')) if data.dig('error', 'message')

          message_data = data.dig('choices', 0, 'message')
          return unless message_data

          Message.new(
            role: :assistant,
            content: message_data['content'],
            tool_calls: parse_tool_calls(message_data['tool_calls']),
            input_tokens: data['usage']['prompt_tokens'],
            output_tokens: data['usage']['completion_tokens'],
            model_id: data['model'],
            raw: response
          )
        end

        def format_messages(messages)
          messages.map do |msg|
            {
              role: format_role(msg.role),
              content: Media.format_content(msg.content),
              tool_calls: format_tool_calls(msg.tool_calls),
              tool_call_id: msg.tool_call_id
            }.compact
          end
        end

        def format_role(role)
          case role
          when :system
            @config.openai_use_system_role ? 'system' : 'developer'
          else
            role.to_s
          end
        end
      end
    end
  end
end
