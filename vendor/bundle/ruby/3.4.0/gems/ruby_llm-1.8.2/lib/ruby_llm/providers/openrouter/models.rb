# frozen_string_literal: true

module RubyLLM
  module Providers
    class OpenRouter
      # Models methods of the OpenRouter API integration
      module Models
        module_function

        def models_url
          'models'
        end

        def parse_list_models_response(response, slug, _capabilities)
          Array(response.body['data']).map do |model_data| # rubocop:disable Metrics/BlockLength
            modalities = {
              input: Array(model_data.dig('architecture', 'input_modalities')),
              output: Array(model_data.dig('architecture', 'output_modalities'))
            }

            pricing = { text_tokens: { standard: {} } }

            pricing_types = {
              prompt: :input_per_million,
              completion: :output_per_million,
              input_cache_read: :cached_input_per_million,
              internal_reasoning: :reasoning_output_per_million
            }

            pricing_types.each do |source_key, target_key|
              value = model_data.dig('pricing', source_key.to_s).to_f
              pricing[:text_tokens][:standard][target_key] = value * 1_000_000 if value.positive?
            end

            capabilities = supported_parameters_to_capabilities(model_data['supported_parameters'])

            Model::Info.new(
              id: model_data['id'],
              name: model_data['name'],
              provider: slug,
              family: model_data['id'].split('/').first,
              created_at: model_data['created'] ? Time.at(model_data['created']) : nil,
              context_window: model_data['context_length'],
              max_output_tokens: model_data.dig('top_provider', 'max_completion_tokens'),
              modalities: modalities,
              capabilities: capabilities,
              pricing: pricing,
              metadata: {
                description: model_data['description'],
                architecture: model_data['architecture'],
                top_provider: model_data['top_provider'],
                per_request_limits: model_data['per_request_limits'],
                supported_parameters: model_data['supported_parameters']
              }
            )
          end
        end

        def supported_parameters_to_capabilities(params)
          return [] unless params

          capabilities = []
          capabilities << 'streaming'
          capabilities << 'function_calling' if params.include?('tools') || params.include?('tool_choice')
          capabilities << 'structured_output' if params.include?('response_format')
          capabilities << 'batch' if params.include?('batch')
          capabilities << 'predicted_outputs' if params.include?('logit_bias') && params.include?('top_k')
          capabilities
        end
      end
    end
  end
end
