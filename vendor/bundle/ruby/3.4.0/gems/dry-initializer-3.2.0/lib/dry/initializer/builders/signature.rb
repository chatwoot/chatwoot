# frozen_string_literal: true

module Dry
  module Initializer
    module Builders
      # @private
      class Signature
        def self.[](config)
          new(config).call
        end

        def call
          [*required_params, *optional_params, "*", options].compact.join(", ")
        end

        private

        def initialize(config)
          @config  = config
          @options = config.options.any?
          @null    = config.null ? "Dry::Initializer::UNDEFINED" : "nil"
        end

        def required_params
          @config.params.reject(&:optional).map(&:source)
        end

        def optional_params
          @config.params.select(&:optional).map { |rec| "#{rec.source} = #{@null}" }
        end

        def options
          "**__dry_initializer_options__" if @options
        end
      end
    end
  end
end
