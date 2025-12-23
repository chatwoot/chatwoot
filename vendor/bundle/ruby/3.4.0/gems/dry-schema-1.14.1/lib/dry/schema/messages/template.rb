# frozen_string_literal: true

require "dry/initializer"
require "dry/core/equalizer"

require "dry/schema/constants"

module Dry
  module Schema
    module Messages
      # @api private
      class Template
        extend ::Dry::Initializer
        include ::Dry::Equalizer(:messages, :key, :options)

        option :messages
        option :key
        option :options

        # @api private
        def data(data = EMPTY_HASH)
          ensure_message!
          messages.interpolatable_data(key, options, **options, **data)
        end

        # @api private
        def call(data = EMPTY_HASH)
          ensure_message!
          messages.interpolate(key, options, **data)
        end
        alias_method :[], :call

        private

        def ensure_message!
          return if messages.key?(key, options)

          raise KeyError, "No message found for template, template=#{inspect}"
        end
      end
    end
  end
end
