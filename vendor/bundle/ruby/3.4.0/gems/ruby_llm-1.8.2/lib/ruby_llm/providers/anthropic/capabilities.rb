# frozen_string_literal: true

module RubyLLM
  module Providers
    class Anthropic
      # Determines capabilities and pricing for Anthropic models
      module Capabilities
        module_function

        def determine_context_window(_model_id)
          200_000
        end

        def determine_max_tokens(model_id)
          case model_id
          when /claude-3-7-sonnet/, /claude-3-5/ then 8_192
          else 4_096
          end
        end

        def get_input_price(model_id)
          PRICES.dig(model_family(model_id), :input) || default_input_price
        end

        def get_output_price(model_id)
          PRICES.dig(model_family(model_id), :output) || default_output_price
        end

        def supports_vision?(model_id)
          !model_id.match?(/claude-[12]/)
        end

        def supports_functions?(model_id)
          model_id.match?(/claude-3/)
        end

        def supports_json_mode?(model_id)
          model_id.match?(/claude-3/)
        end

        def supports_extended_thinking?(model_id)
          model_id.match?(/claude-3-7-sonnet/)
        end

        def model_family(model_id)
          case model_id
          when /claude-3-7-sonnet/  then 'claude-3-7-sonnet'
          when /claude-3-5-sonnet/  then 'claude-3-5-sonnet'
          when /claude-3-5-haiku/   then 'claude-3-5-haiku'
          when /claude-3-opus/      then 'claude-3-opus'
          when /claude-3-sonnet/    then 'claude-3-sonnet'
          when /claude-3-haiku/     then 'claude-3-haiku'
          else 'claude-2'
          end
        end

        def model_type(_)
          'chat'
        end

        PRICES = {
          'claude-3-7-sonnet': { input: 3.0, output: 15.0 },
          'claude-3-5-sonnet': { input: 3.0, output: 15.0 },
          'claude-3-5-haiku': { input: 0.80, output: 4.0 },
          'claude-3-opus': { input: 15.0, output: 75.0 },
          'claude-3-haiku': { input: 0.25, output: 1.25 },
          'claude-2': { input: 3.0, output: 15.0 }
        }.freeze

        def default_input_price
          3.0
        end

        def default_output_price
          15.0
        end

        def modalities_for(model_id)
          modalities = {
            input: ['text'],
            output: ['text']
          }

          unless model_id.match?(/claude-[12]/)
            modalities[:input] << 'image'
            modalities[:input] << 'pdf'
          end

          modalities
        end

        def capabilities_for(model_id)
          capabilities = ['streaming']

          if model_id.match?(/claude-3/)
            capabilities << 'function_calling'
            capabilities << 'batch'
          end

          capabilities << 'reasoning' if model_id.match?(/claude-3-7|-4/)
          capabilities << 'citations' if model_id.match?(/claude-3\.5|claude-3-7/)
          capabilities
        end

        def pricing_for(model_id)
          family = model_family(model_id)
          prices = PRICES.fetch(family.to_sym, { input: default_input_price, output: default_output_price })

          standard_pricing = {
            input_per_million: prices[:input],
            output_per_million: prices[:output]
          }

          batch_pricing = {
            input_per_million: prices[:input] * 0.5,
            output_per_million: prices[:output] * 0.5
          }

          if model_id.match?(/claude-3-7/)
            standard_pricing[:reasoning_output_per_million] = prices[:output] * 2.5
            batch_pricing[:reasoning_output_per_million] = prices[:output] * 1.25
          end

          {
            text_tokens: {
              standard: standard_pricing,
              batch: batch_pricing
            }
          }
        end
      end
    end
  end
end
