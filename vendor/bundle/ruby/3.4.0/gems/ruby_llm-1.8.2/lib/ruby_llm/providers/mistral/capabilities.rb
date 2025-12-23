# frozen_string_literal: true

module RubyLLM
  module Providers
    class Mistral
      # Determines capabilities for Mistral models
      module Capabilities
        module_function

        def supports_streaming?(model_id)
          !model_id.match?(/embed|moderation|ocr|transcriptions/)
        end

        def supports_tools?(model_id)
          !model_id.match?(/embed|moderation|ocr|voxtral|transcriptions|mistral-(tiny|small)-(2312|2402)/)
        end

        def supports_vision?(model_id)
          model_id.match?(/pixtral|mistral-small-(2503|2506)|mistral-medium/)
        end

        def supports_json_mode?(model_id)
          !model_id.match?(/embed|moderation|ocr|voxtral|transcriptions/) && supports_tools?(model_id)
        end

        def format_display_name(model_id)
          case model_id
          when /mistral-large/ then 'Mistral Large'
          when /mistral-medium/ then 'Mistral Medium'
          when /mistral-small/ then 'Mistral Small'
          when /ministral-3b/ then 'Ministral 3B'
          when /ministral-8b/ then 'Ministral 8B'
          when /codestral/ then 'Codestral'
          when /pixtral-large/ then 'Pixtral Large'
          when /pixtral-12b/ then 'Pixtral 12B'
          when /mistral-embed/ then 'Mistral Embed'
          when /mistral-moderation/ then 'Mistral Moderation'
          else model_id.split('-').map(&:capitalize).join(' ')
          end
        end

        def model_family(model_id)
          case model_id
          when /mistral-large/ then 'mistral-large'
          when /mistral-medium/ then 'mistral-medium'
          when /mistral-small/ then 'mistral-small'
          when /ministral/ then 'ministral'
          when /codestral/ then 'codestral'
          when /pixtral/ then 'pixtral'
          when /mistral-embed/ then 'mistral-embed'
          when /mistral-moderation/ then 'mistral-moderation'
          else 'mistral'
          end
        end

        def context_window_for(_model_id)
          32_768
        end

        def max_tokens_for(_model_id)
          8192
        end

        def modalities_for(model_id)
          case model_id
          when /pixtral/
            {
              input: %w[text image],
              output: ['text']
            }
          when /embed/
            {
              input: ['text'],
              output: ['embeddings']
            }
          else
            {
              input: ['text'],
              output: ['text']
            }
          end
        end

        def capabilities_for(model_id) # rubocop:disable Metrics/PerceivedComplexity
          case model_id
          when /moderation/ then ['moderation']
          when /voxtral.*transcribe/ then ['transcription']
          when /ocr/ then ['vision']
          else
            capabilities = []
            capabilities << 'streaming' if supports_streaming?(model_id)
            capabilities << 'function_calling' if supports_tools?(model_id)
            capabilities << 'structured_output' if supports_json_mode?(model_id)
            capabilities << 'vision' if supports_vision?(model_id)

            capabilities << 'reasoning' if model_id.match?(/magistral/)
            capabilities << 'batch' unless model_id.match?(/voxtral|ocr|embed|moderation/)
            capabilities << 'fine_tuning' if model_id.match?(/mistral-(small|medium|large)|devstral/)
            capabilities << 'distillation' if model_id.match?(/ministral/)
            capabilities << 'predicted_outputs' if model_id.match?(/codestral/)

            capabilities.uniq
          end
        end

        def pricing_for(_model_id)
          {
            input: 0.0,
            output: 0.0
          }
        end

        def release_date_for(model_id)
          case model_id
          when 'open-mistral-7b', 'mistral-tiny' then '2023-09-27'
          when 'mistral-medium-2312', 'mistral-small-2312', 'mistral-small',
               'open-mixtral-8x7b', 'mistral-tiny-2312' then '2023-12-11'

          when 'mistral-embed' then '2024-01-11'
          when 'mistral-large-2402', 'mistral-small-2402' then '2024-02-26'
          when 'open-mixtral-8x22b', 'open-mixtral-8x22b-2404' then '2024-04-17'
          when 'codestral-2405' then '2024-05-22'
          when 'codestral-mamba-2407', 'codestral-mamba-latest', 'open-codestral-mamba' then '2024-07-16'
          when 'open-mistral-nemo', 'open-mistral-nemo-2407', 'mistral-tiny-2407',
               'mistral-tiny-latest' then '2024-07-18'
          when 'mistral-large-2407' then '2024-07-24'
          when 'pixtral-12b-2409', 'pixtral-12b-latest', 'pixtral-12b' then '2024-09-17'
          when 'mistral-small-2409' then '2024-09-18'
          when 'ministral-3b-2410', 'ministral-3b-latest', 'ministral-8b-2410',
               'ministral-8b-latest' then '2024-10-16'
          when 'pixtral-large-2411', 'pixtral-large-latest', 'mistral-large-pixtral-2411' then '2024-11-12'
          when 'mistral-large-2411', 'mistral-large-latest', 'mistral-large' then '2024-11-20'
          when 'codestral-2411-rc5', 'mistral-moderation-2411', 'mistral-moderation-latest' then '2024-11-26'
          when 'codestral-2412' then '2024-12-17'

          when 'mistral-small-2501' then '2025-01-13'
          when 'codestral-2501' then '2025-01-14'
          when 'mistral-saba-2502', 'mistral-saba-latest' then '2025-02-18'
          when 'mistral-small-2503' then '2025-03-03'
          when 'mistral-ocr-2503' then '2025-03-21'
          when 'mistral-medium', 'mistral-medium-latest', 'mistral-medium-2505' then '2025-05-06'
          when 'codestral-embed', 'codestral-embed-2505' then '2025-05-21'
          when 'mistral-ocr-2505', 'mistral-ocr-latest' then '2025-05-23'
          when 'devstral-small-2505' then '2025-05-28'
          when 'mistral-small-2506', 'mistral-small-latest', 'magistral-medium-2506',
               'magistral-medium-latest' then '2025-06-10'
          when 'devstral-small-2507', 'devstral-small-latest', 'devstral-medium-2507',
               'devstral-medium-latest' then '2025-07-09'
          when 'codestral-2508', 'codestral-latest' then '2025-08-30'
          end
        end
      end
    end
  end
end
