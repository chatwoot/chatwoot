# frozen_string_literal: true

module RubyLLM
  module Providers
    class Gemini
      # Determines capabilities and pricing for Google Gemini models
      module Capabilities
        module_function

        def context_window_for(model_id)
          case model_id
          when /gemini-2\.5-pro-exp-03-25/, /gemini-2\.0-flash/, /gemini-2\.0-flash-lite/, /gemini-1\.5-flash/, /gemini-1\.5-flash-8b/ # rubocop:disable Layout/LineLength
            1_048_576
          when /gemini-1\.5-pro/ then 2_097_152
          when /gemini-embedding-exp/ then 8_192
          when /text-embedding-004/, /embedding-001/ then 2_048
          when /aqa/ then 7_168
          when /imagen-3/ then nil
          else 32_768
          end
        end

        def max_tokens_for(model_id)
          case model_id
          when /gemini-2\.5-pro-exp-03-25/ then 64_000
          when /gemini-2\.0-flash/, /gemini-2\.0-flash-lite/, /gemini-1\.5-flash/, /gemini-1\.5-flash-8b/, /gemini-1\.5-pro/ # rubocop:disable Layout/LineLength
            8_192
          when /gemini-embedding-exp/ then nil
          when /text-embedding-004/, /embedding-001/ then 768
          when /imagen-3/ then 4
          else 4_096
          end
        end

        def input_price_for(model_id)
          base_price = PRICES.dig(pricing_family(model_id), :input) || default_input_price
          return base_price unless long_context_model?(model_id)

          context_window_for(model_id) > 128_000 ? base_price * 2 : base_price
        end

        def output_price_for(model_id)
          base_price = PRICES.dig(pricing_family(model_id), :output) || default_output_price
          return base_price unless long_context_model?(model_id)

          context_window_for(model_id) > 128_000 ? base_price * 2 : base_price
        end

        def supports_vision?(model_id)
          return false if model_id.match?(/text-embedding|embedding-001|aqa/)

          model_id.match?(/gemini|flash|pro|imagen/)
        end

        def supports_video?(model_id)
          model_id.match?(/gemini/)
        end

        def supports_functions?(model_id)
          return false if model_id.match?(/text-embedding|embedding-001|aqa|flash-lite|imagen|gemini-2\.0-flash-lite/)

          model_id.match?(/gemini|pro|flash/)
        end

        def supports_json_mode?(model_id)
          if model_id.match?(/text-embedding|embedding-001|aqa|imagen|gemini-2\.0-flash-lite|gemini-2\.5-pro-exp-03-25/)
            return false
          end

          model_id.match?(/gemini|pro|flash/)
        end

        def format_display_name(model_id)
          model_id
            .delete_prefix('models/')
            .split('-')
            .map(&:capitalize)
            .join(' ')
            .gsub(/(\d+\.\d+)/, ' \1')
            .gsub(/\s+/, ' ')
            .gsub('Aqa', 'AQA')
            .strip
        end

        def supports_caching?(model_id)
          if model_id.match?(/flash-lite|gemini-2\.5-pro-exp-03-25|aqa|imagen|text-embedding|embedding-001/)
            return false
          end

          model_id.match?(/gemini|pro|flash/)
        end

        def supports_tuning?(model_id)
          model_id.match?(/gemini-1\.5-flash|gemini-1\.5-flash-8b/)
        end

        def supports_audio?(model_id)
          model_id.match?(/gemini|pro|flash/)
        end

        def model_type(model_id)
          case model_id
          when /text-embedding|embedding|gemini-embedding/ then 'embedding'
          when /imagen/ then 'image'
          else 'chat'
          end
        end

        def model_family(model_id)
          case model_id
          when /gemini-2\.5-pro-exp-03-25/ then 'gemini25_pro_exp'
          when /gemini-2\.0-flash-lite/ then 'gemini20_flash_lite'
          when /gemini-2\.0-flash/ then 'gemini20_flash'
          when /gemini-1\.5-flash-8b/ then 'gemini15_flash_8b'
          when /gemini-1\.5-flash/ then 'gemini15_flash'
          when /gemini-1\.5-pro/ then 'gemini15_pro'
          when /gemini-embedding-exp/ then 'gemini_embedding_exp'
          when /text-embedding-004/ then 'embedding4'
          when /embedding-001/ then 'embedding1'
          when /aqa/ then 'aqa'
          when /imagen-3/ then 'imagen3'
          else 'other'
          end
        end

        def pricing_family(model_id)
          case model_id
          when /gemini-2\.5-pro-exp-03-25/ then :pro_2_5 # rubocop:disable Naming/VariableNumber
          when /gemini-2\.0-flash-lite/ then :flash_lite_2 # rubocop:disable Naming/VariableNumber
          when /gemini-2\.0-flash/ then :flash_2 # rubocop:disable Naming/VariableNumber
          when /gemini-1\.5-flash-8b/ then :flash_8b
          when /gemini-1\.5-flash/ then :flash
          when /gemini-1\.5-pro/ then :pro
          when /gemini-embedding-exp/ then :gemini_embedding
          when /text-embedding|embedding/ then :embedding
          when /imagen/ then :imagen
          when /aqa/ then :aqa
          else :base
          end
        end

        def long_context_model?(model_id)
          model_id.match?(/gemini-1\.5-(?:pro|flash)|gemini-1\.5-flash-8b/)
        end

        def context_length(model_id)
          context_window_for(model_id)
        end

        PRICES = {
          flash_2: { # rubocop:disable Naming/VariableNumber
            input: 0.10,
            output: 0.40,
            audio_input: 0.70,
            cache: 0.025,
            cache_storage: 1.00,
            grounding_search: 35.00
          },
          flash_lite_2: { # rubocop:disable Naming/VariableNumber
            input: 0.075,
            output: 0.30
          },
          flash: {
            input: 0.075,
            output: 0.30,
            cache: 0.01875,
            cache_storage: 1.00,
            grounding_search: 35.00
          },
          flash_8b: {
            input: 0.0375,
            output: 0.15,
            cache: 0.01,
            cache_storage: 0.25,
            grounding_search: 35.00
          },
          pro: {
            input: 1.25,
            output: 5.0,
            cache: 0.3125,
            cache_storage: 4.50,
            grounding_search: 35.00
          },
          pro_2_5: { # rubocop:disable Naming/VariableNumber
            input: 0.12,
            output: 0.50
          },
          gemini_embedding: {
            input: 0.002,
            output: 0.004
          },
          embedding: {
            input: 0.00,
            output: 0.00
          },
          imagen: {
            price: 0.03
          },
          aqa: {
            input: 0.00,
            output: 0.00
          }
        }.freeze

        def default_input_price
          0.075
        end

        def default_output_price
          0.30
        end

        def modalities_for(model_id)
          modalities = {
            input: ['text'],
            output: ['text']
          }

          if supports_vision?(model_id)
            modalities[:input] << 'image'
            modalities[:input] << 'pdf'
          end

          modalities[:input] << 'video' if supports_video?(model_id)
          modalities[:input] << 'audio' if model_id.match?(/audio/)
          modalities[:output] << 'embeddings' if model_id.match?(/embedding|gemini-embedding/)
          modalities[:output] = ['image'] if model_id.match?(/imagen/)

          modalities
        end

        def capabilities_for(model_id)
          capabilities = ['streaming']

          capabilities << 'function_calling' if supports_functions?(model_id)
          capabilities << 'structured_output' if supports_json_mode?(model_id)
          capabilities << 'batch' if model_id.match?(/embedding|flash/)
          capabilities << 'caching' if supports_caching?(model_id)
          capabilities << 'fine_tuning' if supports_tuning?(model_id)
          capabilities
        end

        def pricing_for(model_id)
          family = pricing_family(model_id)
          prices = PRICES.fetch(family, { input: default_input_price, output: default_output_price })

          standard_pricing = {
            input_per_million: prices[:input],
            output_per_million: prices[:output]
          }

          standard_pricing[:cached_input_per_million] = prices[:input_hit] if prices[:input_hit]

          batch_pricing = {
            input_per_million: (standard_pricing[:input_per_million] || 0) * 0.5,
            output_per_million: (standard_pricing[:output_per_million] || 0) * 0.5
          }

          if standard_pricing[:cached_input_per_million]
            batch_pricing[:cached_input_per_million] = standard_pricing[:cached_input_per_million] * 0.5
          end

          pricing = {
            text_tokens: {
              standard: standard_pricing,
              batch: batch_pricing
            }
          }

          if model_id.match?(/embedding|gemini-embedding/)
            pricing[:embeddings] = {
              standard: { input_per_million: prices[:price] || 0.002 }
            }
          end

          pricing
        end
      end
    end
  end
end
