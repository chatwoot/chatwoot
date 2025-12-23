# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Utils
        module Quantization
          # Quantization for Hash
          module Hash
            PLACEHOLDER = '?'
            EXCLUDE_KEYS = [].freeze
            SHOW_KEYS = [].freeze
            DEFAULT_OPTIONS = {
              exclude: EXCLUDE_KEYS,
              show: SHOW_KEYS,
              placeholder: PLACEHOLDER
            }.freeze

            module_function

            def format(hash_obj, options = {})
              options ||= {}
              format!(hash_obj, options)
            rescue StandardError
              options[:placeholder] || PLACEHOLDER
            end

            def format!(hash_obj, options = {})
              options ||= {}
              options = merge_options(DEFAULT_OPTIONS, options)
              format_hash(hash_obj, options)
            end

            def format_hash(hash_obj, options = {})
              case hash_obj
              when ::Hash
                return {} if options[:exclude] == :all
                return hash_obj if options[:show] == :all

                hash_obj.each_with_object({}) do |(key, value), quantized|
                  if options[:show].any?(&indifferent_equals(key))
                    quantized[key] = value
                  elsif options[:exclude].none?(&indifferent_equals(key))
                    quantized[key] = format_value(value, options)
                  end
                end
              else
                format_value(hash_obj, options)
              end
            end

            def format_value(value, options = {})
              return value if options[:show] == :all

              case value
              when ::Hash
                format_hash(value, options)
              when Array
                # If any are objects, format them.
                format_array(value, options)
              else
                options[:placeholder]
              end
            end

            def format_array(value, options)
              if value.any? { |v| v.class <= ::Hash || v.class <= Array }
                first_entry = format_value(value.first, options)
                value.size > 1 ? [first_entry, options[:placeholder]] : [first_entry]
                # Otherwise short-circuit and return single placeholder
              else
                [options[:placeholder]]
              end
            end

            def merge_options(original, additional)
              {}.tap do |options|
                # Show
                # If either is :all, value becomes :all
                options[:show] =  if original[:show] == :all || additional[:show] == :all
                                    :all
                                  else
                                    (original[:show] || []).dup.concat(additional[:show] || []).uniq
                                  end

                # Exclude
                # If either is :all, value becomes :all
                options[:exclude] = if original[:exclude] == :all || additional[:exclude] == :all
                                      :all
                                    else
                                      (original[:exclude] || []).dup.concat(additional[:exclude] || []).uniq
                                    end

                options[:placeholder] = additional[:placeholder] || original[:placeholder]
              end
            end

            def indifferent_equals(value)
              value = convert_value(value)
              ->(compared_value) { value == convert_value(compared_value) }
            end

            def convert_value(value)
              value.is_a?(Symbol) ? value.to_s : value
            end
          end
        end
      end
    end
  end
end
