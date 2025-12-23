# frozen_string_literal: true

module RubyLLM
  module Providers
    class OpenAI
      # Determines capabilities and pricing for OpenAI models
      module Capabilities
        module_function

        MODEL_PATTERNS = {
          dall_e: /^dall-e/,
          chatgpt4o: /^chatgpt-4o/,
          gpt41: /^gpt-4\.1(?!-(?:mini|nano))/,
          gpt41_mini: /^gpt-4\.1-mini/,
          gpt41_nano: /^gpt-4\.1-nano/,
          gpt4: /^gpt-4(?:-\d{6})?$/,
          gpt4_turbo: /^gpt-4(?:\.5)?-(?:\d{6}-)?(preview|turbo)/,
          gpt35_turbo: /^gpt-3\.5-turbo/,
          gpt4o: /^gpt-4o(?!-(?:mini|audio|realtime|transcribe|tts|search))/,
          gpt4o_audio: /^gpt-4o-(?:audio)/,
          gpt4o_mini: /^gpt-4o-mini(?!-(?:audio|realtime|transcribe|tts|search))/,
          gpt4o_mini_audio: /^gpt-4o-mini-audio/,
          gpt4o_mini_realtime: /^gpt-4o-mini-realtime/,
          gpt4o_mini_transcribe: /^gpt-4o-mini-transcribe/,
          gpt4o_mini_tts: /^gpt-4o-mini-tts/,
          gpt4o_realtime: /^gpt-4o-realtime/,
          gpt4o_search: /^gpt-4o-search/,
          gpt4o_transcribe: /^gpt-4o-transcribe/,
          gpt5: /^gpt-5/,
          gpt5_mini: /^gpt-5-mini/,
          gpt5_nano: /^gpt-5-nano/,
          o1: /^o1(?!-(?:mini|pro))/,
          o1_mini: /^o1-mini/,
          o1_pro: /^o1-pro/,
          o3_mini: /^o3-mini/,
          babbage: /^babbage/,
          davinci: /^davinci/,
          embedding3_large: /^text-embedding-3-large/,
          embedding3_small: /^text-embedding-3-small/,
          embedding_ada: /^text-embedding-ada/,
          tts1: /^tts-1(?!-hd)/,
          tts1_hd: /^tts-1-hd/,
          whisper: /^whisper/,
          moderation: /^(?:omni|text)-moderation/
        }.freeze

        def context_window_for(model_id)
          case model_family(model_id)
          when 'gpt41', 'gpt41_mini', 'gpt41_nano' then 1_047_576
          when 'gpt5', 'gpt5_mini', 'gpt5_nano', 'chatgpt4o', 'gpt4_turbo', 'gpt4o', 'gpt4o_audio', 'gpt4o_mini',
               'gpt4o_mini_audio', 'gpt4o_mini_realtime', 'gpt4o_realtime',
               'gpt4o_search', 'gpt4o_transcribe', 'gpt4o_mini_search', 'o1_mini' then 128_000
          when 'gpt4' then 8_192
          when 'gpt4o_mini_transcribe' then 16_000
          when 'o1', 'o1_pro', 'o3_mini' then 200_000
          when 'gpt35_turbo' then 16_385
          when 'gpt4o_mini_tts', 'tts1', 'tts1_hd', 'whisper', 'moderation',
               'embedding3_large', 'embedding3_small', 'embedding_ada' then nil
          else 4_096
          end
        end

        def max_tokens_for(model_id)
          case model_family(model_id)
          when 'gpt5', 'gpt5_mini', 'gpt5_nano' then 400_000
          when 'gpt41', 'gpt41_mini', 'gpt41_nano' then 32_768
          when 'chatgpt4o', 'gpt4o', 'gpt4o_mini', 'gpt4o_mini_search' then 16_384
          when 'babbage', 'davinci' then 16_384 # rubocop:disable Lint/DuplicateBranch
          when 'gpt4' then 8_192
          when 'gpt35_turbo' then 4_096
          when 'gpt4_turbo', 'gpt4o_realtime', 'gpt4o_mini_realtime' then 4_096 # rubocop:disable Lint/DuplicateBranch
          when 'gpt4o_mini_transcribe' then 2_000
          when 'o1', 'o1_pro', 'o3_mini' then 100_000
          when 'o1_mini' then 65_536
          when 'gpt4o_mini_tts', 'tts1', 'tts1_hd', 'whisper', 'moderation',
               'embedding3_large', 'embedding3_small', 'embedding_ada' then nil
          else 16_384 # rubocop:disable Lint/DuplicateBranch
          end
        end

        def supports_vision?(model_id)
          case model_family(model_id)
          when 'gpt5', 'gpt5_mini', 'gpt5_nano', 'gpt41', 'gpt41_mini', 'gpt41_nano', 'chatgpt4o', 'gpt4',
               'gpt4_turbo', 'gpt4o', 'gpt4o_mini', 'o1', 'o1_pro', 'moderation', 'gpt4o_search',
               'gpt4o_mini_search' then true
          else false
          end
        end

        def supports_functions?(model_id)
          case model_family(model_id)
          when 'gpt5', 'gpt5_mini', 'gpt5_nano', 'gpt41', 'gpt41_mini', 'gpt41_nano', 'gpt4', 'gpt4_turbo', 'gpt4o',
               'gpt4o_mini', 'o1', 'o1_pro', 'o3_mini' then true
          when 'chatgpt4o', 'gpt35_turbo', 'o1_mini', 'gpt4o_mini_tts',
               'gpt4o_transcribe', 'gpt4o_search', 'gpt4o_mini_search' then false
          else false # rubocop:disable Lint/DuplicateBranch
          end
        end

        def supports_structured_output?(model_id)
          case model_family(model_id)
          when 'gpt5', 'gpt5_mini', 'gpt5_nano', 'gpt41', 'gpt41_mini', 'gpt41_nano', 'chatgpt4o', 'gpt4o',
               'gpt4o_mini', 'o1', 'o1_pro', 'o3_mini' then true
          else false
          end
        end

        def supports_json_mode?(model_id)
          supports_structured_output?(model_id)
        end

        PRICES = {
          gpt5: { input: 1.25, output: 10.0, cached_input: 0.125 },
          gpt5_mini: { input: 0.25, output: 2.0, cached_input: 0.025 },
          gpt5_nano: { input: 0.05, output: 0.4, cached_input: 0.005 },
          gpt41: { input: 2.0, output: 8.0, cached_input: 0.5 },
          gpt41_mini: { input: 0.4, output: 1.6, cached_input: 0.1 },
          gpt41_nano: { input: 0.1, output: 0.4 },
          chatgpt4o: { input: 5.0, output: 15.0 },
          gpt4: { input: 10.0, output: 30.0 },
          gpt4_turbo: { input: 10.0, output: 30.0 },
          gpt45: { input: 75.0, output: 150.0 },
          gpt35_turbo: { input: 0.5, output: 1.5 },
          gpt4o: { input: 2.5, output: 10.0 },
          gpt4o_audio: { input: 2.5, output: 10.0, audio_input: 40.0, audio_output: 80.0 },
          gpt4o_mini: { input: 0.15, output: 0.6 },
          gpt4o_mini_audio: { input: 0.15, output: 0.6, audio_input: 10.0, audio_output: 20.0 },
          gpt4o_mini_realtime: { input: 0.6, output: 2.4 },
          gpt4o_mini_transcribe: { input: 1.25, output: 5.0, audio_input: 3.0 },
          gpt4o_mini_tts: { input: 0.6, output: 12.0 },
          gpt4o_realtime: { input: 5.0, output: 20.0 },
          gpt4o_search: { input: 2.5, output: 10.0 },
          gpt4o_transcribe: { input: 2.5, output: 10.0, audio_input: 6.0 },
          o1: { input: 15.0, output: 60.0 },
          o1_mini: { input: 1.1, output: 4.4 },
          o1_pro: { input: 150.0, output: 600.0 },
          o3_mini: { input: 1.1, output: 4.4 },
          babbage: { input: 0.4, output: 0.4 },
          davinci: { input: 2.0, output: 2.0 },
          embedding3_large: { price: 0.13 },
          embedding3_small: { price: 0.02 },
          embedding_ada: { price: 0.10 },
          tts1: { price: 15.0 },
          tts1_hd: { price: 30.0 },
          whisper: { price: 0.006 },
          moderation: { price: 0.0 }
        }.freeze

        def model_family(model_id)
          MODEL_PATTERNS.each do |family, pattern|
            return family.to_s if model_id.match?(pattern)
          end
          'other'
        end

        def input_price_for(model_id)
          family = model_family(model_id).to_sym
          prices = PRICES.fetch(family, { input: default_input_price })
          prices[:input] || prices[:price] || default_input_price
        end

        def cached_input_price_for(model_id)
          family = model_family(model_id).to_sym
          prices = PRICES.fetch(family, {})
          prices[:cached_input]
        end

        def output_price_for(model_id)
          family = model_family(model_id).to_sym
          prices = PRICES.fetch(family, { output: default_output_price })
          prices[:output] || prices[:price] || default_output_price
        end

        def model_type(model_id)
          case model_family(model_id)
          when /embedding/ then 'embedding'
          when /^tts|whisper|gpt4o_(?:mini_)?(?:transcribe|tts)$/ then 'audio'
          when 'moderation' then 'moderation'
          when /dall/ then 'image'
          else 'chat'
          end
        end

        def default_input_price
          0.50
        end

        def default_output_price
          1.50
        end

        def format_display_name(model_id)
          model_id.then { |id| humanize(id) }
                  .then { |name| apply_special_formatting(name) }
        end

        def humanize(id)
          id.tr('-', ' ')
            .split
            .map(&:capitalize)
            .join(' ')
        end

        def apply_special_formatting(name)
          name
            .gsub(/(\d{4}) (\d{2}) (\d{2})/, '\1\2\3')
            .gsub(/^(?:Gpt|Chatgpt|Tts|Dall E) /) { |m| special_prefix_format(m.strip) }
            .gsub(/^O([13]) /, 'O\1-')
            .gsub(/^O[13] Mini/, '\0'.tr(' ', '-'))
            .gsub(/\d\.\d /, '\0'.sub(' ', '-'))
            .gsub(/4o (?=Mini|Preview|Turbo|Audio|Realtime|Transcribe|Tts)/, '4o-')
            .gsub(/\bHd\b/, 'HD')
            .gsub(/(?:Omni|Text) Moderation/, '\0'.tr(' ', '-'))
            .gsub('Text Embedding', 'text-embedding-')
        end

        def special_prefix_format(prefix)
          case prefix # rubocop:disable Style/HashLikeCase
          when 'Gpt' then 'GPT-'
          when 'Chatgpt' then 'ChatGPT-'
          when 'Tts' then 'TTS-'
          when 'Dall E' then 'DALL-E-'
          end
        end

        def self.normalize_temperature(temperature, model_id)
          if model_id.match?(/^(o\d|gpt-5)/)
            RubyLLM.logger.debug "Model #{model_id} requires temperature=1.0, ignoring provided value"
            1.0
          elsif model_id.match?(/-search/)
            RubyLLM.logger.debug "Model #{model_id} does not accept temperature parameter, removing"
            nil
          else
            temperature
          end
        end

        def modalities_for(model_id)
          modalities = {
            input: ['text'],
            output: ['text']
          }

          # Vision support
          modalities[:input] << 'image' if supports_vision?(model_id)
          modalities[:input] << 'audio' if model_id.match?(/whisper|audio|tts|transcribe/)
          modalities[:input] << 'pdf' if supports_vision?(model_id)
          modalities[:output] << 'audio' if model_id.match?(/tts|audio/)
          modalities[:output] << 'image' if model_id.match?(/dall-e|image/)
          modalities[:output] << 'embeddings' if model_id.match?(/embedding/)
          modalities[:output] << 'moderation' if model_id.match?(/moderation/)

          modalities
        end

        def capabilities_for(model_id) # rubocop:disable Metrics/PerceivedComplexity
          capabilities = []

          capabilities << 'streaming' unless model_id.match?(/moderation|embedding/)
          capabilities << 'function_calling' if supports_functions?(model_id)
          capabilities << 'structured_output' if supports_json_mode?(model_id)
          capabilities << 'batch' if model_id.match?(/embedding|batch/)
          capabilities << 'reasoning' if model_id.match?(/o\d|gpt-5|codex/)

          if model_id.match?(/gpt-4-turbo|gpt-4o/)
            capabilities << 'image_generation' if model_id.match?(/vision/)
            capabilities << 'speech_generation' if model_id.match?(/audio/)
            capabilities << 'transcription' if model_id.match?(/audio/)
          end

          capabilities
        end

        def pricing_for(model_id)
          standard_pricing = {
            input_per_million: input_price_for(model_id),
            output_per_million: output_price_for(model_id)
          }

          if respond_to?(:cached_input_price_for)
            cached_price = cached_input_price_for(model_id)
            standard_pricing[:cached_input_per_million] = cached_price if cached_price
          end

          pricing = { text_tokens: { standard: standard_pricing } }

          if model_id.match?(/embedding|batch/)
            pricing[:text_tokens][:batch] = {
              input_per_million: standard_pricing[:input_per_million] * 0.5,
              output_per_million: standard_pricing[:output_per_million] * 0.5
            }
          end

          pricing
        end
      end
    end
  end
end
