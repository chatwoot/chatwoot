# frozen_string_literal: true

module RubyLLM
  module Providers
    class GPUStack
      # Models methods of the GPUStack API integration
      module Models
        module_function

        def models_url
          'models'
        end

        def parse_list_models_response(response, slug, _capabilities)
          items = response.body['items'] || []
          items.map do |model|
            Model::Info.new(
              id: model['name'],
              name: model['name'],
              created_at: model['created_at'] ? Time.parse(model['created_at']) : nil,
              provider: slug,
              family: 'gpustack',
              metadata: {
                description: model['description'],
                source: model['source'],
                huggingface_repo_id: model['huggingface_repo_id'],
                ollama_library_model_name: model['ollama_library_model_name'],
                backend: model['backend'],
                meta: model['meta'],
                categories: model['categories']
              },
              context_window: model.dig('meta', 'n_ctx'),
              max_output_tokens: model.dig('meta', 'n_ctx'),
              capabilities: build_capabilities(model),
              modalities: build_modalities(model),
              pricing: {}
            )
          end
        end

        private

        def determine_model_type(model)
          return 'embedding' if model['categories']&.include?('embedding')
          return 'chat' if model['categories']&.include?('llm')

          'other'
        end

        def build_capabilities(model) # rubocop:disable Metrics/PerceivedComplexity
          capabilities = []

          # Add streaming by default for LLM models
          capabilities << 'streaming' if model['categories']&.include?('llm')

          # Map GPUStack metadata to standard capabilities
          capabilities << 'function_calling' if model.dig('meta', 'support_tool_calls')
          capabilities << 'vision' if model.dig('meta', 'support_vision')
          capabilities << 'reasoning' if model.dig('meta', 'support_reasoning')

          # GPUStack models generally support structured output and json mode
          capabilities << 'structured_output' if model['categories']&.include?('llm')
          capabilities << 'json_mode' if model['categories']&.include?('llm')

          capabilities
        end

        def build_modalities(model)
          input_modalities = []
          output_modalities = []

          if model['categories']&.include?('llm')
            input_modalities << 'text'
            input_modalities << 'image' if model.dig('meta', 'support_vision')
            input_modalities << 'audio' if model.dig('meta', 'support_audio')
            output_modalities << 'text'
          elsif model['categories']&.include?('embedding')
            input_modalities << 'text'
            output_modalities << 'embeddings'
          end

          {
            input: input_modalities,
            output: output_modalities
          }
        end
      end
    end
  end
end
