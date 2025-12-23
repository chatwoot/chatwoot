# frozen_string_literal: true

module Slack
  module Web
    module Api
      module Options
        def encode_options_as_json(options, keys)
          encoded_options = options.slice(*keys).transform_values do |value|
            encode_json(value)
          end
          options.merge(encoded_options)
        end

        private

        def encode_json(value)
          if value.is_a?(String)
            value
          else
            JSON.dump(value)
          end
        end
      end
    end
  end
end
