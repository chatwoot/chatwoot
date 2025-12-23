# frozen_string_literal: true

module RubyLLM
  module Providers
    class DeepSeek
      # Determines capabilities and pricing for DeepSeek models
      module Capabilities
        module_function

        def context_window_for(model_id)
          case model_id
          when /deepseek-(?:chat|reasoner)/ then 64_000
          else 32_768
          end
        end

        def max_tokens_for(model_id)
          case model_id
          when /deepseek-(?:chat|reasoner)/ then 8_192
          else 4_096
          end
        end

        def input_price_for(model_id)
          PRICES.dig(model_family(model_id), :input_miss) || default_input_price
        end

        def output_price_for(model_id)
          PRICES.dig(model_family(model_id), :output) || default_output_price
        end

        def cache_hit_price_for(model_id)
          PRICES.dig(model_family(model_id), :input_hit) || default_cache_hit_price
        end

        def supports_vision?(_model_id)
          false
        end

        def supports_functions?(model_id)
          model_id.match?(/deepseek-chat/)
        end

        def supports_json_mode?(_model_id)
          false
        end

        def format_display_name(model_id)
          case model_id
          when 'deepseek-chat' then 'DeepSeek V3'
          when 'deepseek-reasoner' then 'DeepSeek R1'
          else
            model_id.split('-')
                    .map(&:capitalize)
                    .join(' ')
          end
        end

        def model_type(_model_id)
          'chat'
        end

        def model_family(model_id)
          case model_id
          when /deepseek-reasoner/ then :reasoner
          else :chat
          end
        end

        PRICES = {
          chat: {
            input_hit: 0.07,
            input_miss: 0.27,
            output: 1.10
          },
          reasoner: {
            input_hit: 0.14,
            input_miss: 0.55,
            output: 2.19
          }
        }.freeze

        def default_input_price
          0.27
        end

        def default_output_price
          1.10
        end

        def default_cache_hit_price
          0.07
        end

        def modalities_for(_model_id)
          {
            input: ['text'],
            output: ['text']
          }
        end

        def capabilities_for(model_id)
          capabilities = ['streaming']

          capabilities << 'function_calling' if model_id.match?(/deepseek-chat/)

          capabilities
        end

        def pricing_for(model_id)
          family = model_family(model_id)
          prices = PRICES.fetch(family, { input_miss: default_input_price, output: default_output_price })

          standard_pricing = {
            input_per_million: prices[:input_miss],
            output_per_million: prices[:output]
          }

          standard_pricing[:cached_input_per_million] = prices[:input_hit] if prices[:input_hit]

          {
            text_tokens: {
              standard: standard_pricing
            }
          }
        end
      end
    end
  end
end
