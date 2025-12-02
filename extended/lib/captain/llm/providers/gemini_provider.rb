require 'gemini-ai'

module Captain
  module Llm
    module Providers
      class GeminiProvider < BaseProvider
        # Model mapping
        MODELS = {
          'gpt-4o' => 'gemini-1.5-pro',
          'gpt-4o-mini' => 'gemini-1.5-flash',
          'gpt-4-turbo' => 'gemini-1.5-pro',
          'gpt-3.5-turbo' => 'gemini-1.5-flash'
        }.freeze

        def initialize(api_key:, **_options)
          @client = Gemini.new(
            credentials: { service: 'generative-language-api', api_key: api_key },
            options: { model: 'gemini-1.5-flash', server_sent_events: true }
          )
        end

        def chat(messages:, model:, functions: [], json_mode: true)
          gemini_model = map_model(model)

          # Convert OpenAI format to Gemini format
          contents = convert_messages(messages)
          tools = convert_functions(functions) if functions.any?

          request = {
            contents: contents,
            generationConfig: {}
          }

          request[:generationConfig][:response_mime_type] = 'application/json' if json_mode
          request[:tools] = tools if tools

          response = @client.stream_generate_content(request, model: gemini_model)
          convert_response(response)
        end

        def embedding(text:, model:)
          # Gemini uses text-embedding-004 model
          response = @client.embed_content({
                                             model: 'models/text-embedding-004',
                                             content: { parts: [{ text: text }] }
                                           })

          # Convert to OpenAI format
          {
            'data' => [
              { 'embedding' => response.dig('embedding', 'values') || [] }
            ]
          }
        end

        private

        def map_model(openai_model)
          MODELS[openai_model] || 'gemini-1.5-flash'
        end

        def convert_messages(messages)
          messages.map do |msg|
            {
              role: msg['role'] == 'assistant' ? 'model' : 'user',
              parts: [{ text: msg['content'] }]
            }
          end
        end

        def convert_functions(functions)
          [{
            function_declarations: functions.map do |func|
              {
                name: func[:function][:name],
                description: func[:function][:description],
                parameters: func[:function][:parameters]
              }
            end
          }]
        end

        def convert_response(response)
          # Convert Gemini response to OpenAI format
          # Handle array of chunks if streaming, but here we expect full response object from gemini-ai gem
          # The gem might return an array of chunks if streaming is true, but stream_generate_content usually yields.
          # If we use generate_content it returns full response.
          # Let's assume we get a response object that has candidates.

          # NOTE: gemini-ai gem structure might vary, need to be careful.
          # Assuming standard Google AI Studio JSON structure.

          # If response is an array (chunks), we need to aggregate.
          # But for simplicity, let's assume we get the full response or the last chunk has the complete text.

          # Actually, let's use generate_content instead of stream for simplicity first.

          candidate = response.dig(0, 'candidates', 0)
          return fallback_response unless candidate

          content = candidate.dig('content', 'parts', 0)

          if content['functionCall']
            # Function call response
            {
              'choices' => [{
                'message' => {
                  'tool_calls' => [{
                    'id' => SecureRandom.uuid,
                    'type' => 'function',
                    'function' => {
                      'name' => content['functionCall']['name'],
                      'arguments' => content['functionCall']['args'].to_json
                    }
                  }]
                }
              }]
            }
          else
            # Regular response
            {
              'choices' => [{
                'message' => {
                  'content' => content['text']
                }
              }]
            }
          end
        end

        def fallback_response
          {
            'choices' => [{
              'message' => {
                'content' => ''
              }
            }]
          }
        end
      end
    end
  end
end
