# frozen_string_literal: true

module RubyLLM
  module Providers
    class Anthropic
      # Models methods of the Anthropic API integration
      module Models
        module_function

        def models_url
          '/v1/models'
        end

        def parse_list_models_response(response, slug, capabilities)
          Array(response.body['data']).map do |model_data|
            model_id = model_data['id']

            Model::Info.new(
              id: model_id,
              name: model_data['display_name'],
              provider: slug,
              family: capabilities.model_family(model_id),
              created_at: Time.parse(model_data['created_at']),
              context_window: capabilities.determine_context_window(model_id),
              max_output_tokens: capabilities.determine_max_tokens(model_id),
              modalities: capabilities.modalities_for(model_id),
              capabilities: capabilities.capabilities_for(model_id),
              pricing: capabilities.pricing_for(model_id),
              metadata: {}
            )
          end
        end

        def extract_model_id(data)
          data.dig('message', 'model')
        end

        def extract_input_tokens(data)
          data.dig('message', 'usage', 'input_tokens')
        end

        def extract_output_tokens(data)
          data.dig('message', 'usage', 'output_tokens') || data.dig('usage', 'output_tokens')
        end
      end
    end
  end
end
