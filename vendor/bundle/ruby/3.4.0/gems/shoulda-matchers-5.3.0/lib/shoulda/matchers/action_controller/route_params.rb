module Shoulda
  module Matchers
    module ActionController
      # @private
      class RouteParams
        PARAMS_TO_SYMBOLIZE = %i{format}.freeze

        def initialize(args)
          @args = args
        end

        def normalize
          if controller_and_action_given_as_string?
            extract_params_from_string
          else
            stringify_params
          end
        end

        protected

        attr_reader :args

        def controller_and_action_given_as_string?
          args[0].is_a?(String)
        end

        def extract_params_from_string
          controller, action = args[0].split('#')
          params = (args[1] || {}).merge(controller: controller, action: action)
          normalize_values(params)
        end

        def stringify_params
          normalize_values(args[0])
        end

        def normalize_values(hash)
          hash.each_with_object({}) do |(key, value), hash_copy|
            hash_copy[key] = symbolize_or_stringify(key, value)
          end
        end

        def symbolize_or_stringify(key, value)
          if PARAMS_TO_SYMBOLIZE.include?(key)
            value.to_sym
          else
            stringify(value)
          end
        end

        def stringify(value)
          if value.is_a?(Array)
            value.map(&:to_param)
          else
            value.to_param
          end
        end
      end
    end
  end
end
