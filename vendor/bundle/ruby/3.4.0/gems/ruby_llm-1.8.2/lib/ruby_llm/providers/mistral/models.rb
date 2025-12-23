# frozen_string_literal: true

module RubyLLM
  module Providers
    class Mistral
      # Model information for Mistral
      module Models
        module_function

        def models_url
          'models'
        end

        def headers(config)
          {
            'Authorization' => "Bearer #{config.mistral_api_key}"
          }
        end

        def parse_list_models_response(response, slug, capabilities)
          Array(response.body['data']).map do |model_data|
            model_id = model_data['id']

            release_date = capabilities.release_date_for(model_id)
            created_at = release_date ? Time.parse(release_date) : nil

            Model::Info.new(
              id: model_id,
              name: capabilities.format_display_name(model_id),
              provider: slug,
              family: capabilities.model_family(model_id),
              created_at: created_at,
              context_window: capabilities.context_window_for(model_id),
              max_output_tokens: capabilities.max_tokens_for(model_id),
              modalities: capabilities.modalities_for(model_id),
              capabilities: capabilities.capabilities_for(model_id),
              pricing: capabilities.pricing_for(model_id),
              metadata: {
                object: model_data['object'],
                owned_by: model_data['owned_by']
              }
            )
          end
        end
      end
    end
  end
end
