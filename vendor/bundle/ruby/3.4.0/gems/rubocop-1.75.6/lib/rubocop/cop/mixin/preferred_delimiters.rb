# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for handling percent literal delimiters.
    class PreferredDelimiters
      attr_reader :type, :config

      PERCENT_LITERAL_TYPES = %w[% %i %I %q %Q %r %s %w %W %x].freeze

      def initialize(type, config, preferred_delimiters)
        @type = type
        @config = config
        @preferred_delimiters = preferred_delimiters
      end

      def delimiters
        preferred_delimiters[type].chars
      end

      private

      def ensure_valid_preferred_delimiters
        invalid = preferred_delimiters_config.keys - (PERCENT_LITERAL_TYPES + %w[default])
        return if invalid.empty?

        raise ArgumentError, "Invalid preferred delimiter config key: #{invalid.join(', ')}"
      end

      def preferred_delimiters
        @preferred_delimiters ||=
          begin
            ensure_valid_preferred_delimiters

            if preferred_delimiters_config.key?('default')
              PERCENT_LITERAL_TYPES.to_h do |type|
                [type, preferred_delimiters_config[type] || preferred_delimiters_config['default']]
              end
            else
              preferred_delimiters_config
            end
          end
      end

      def preferred_delimiters_config
        config.for_cop('Style/PercentLiteralDelimiters')['PreferredDelimiters']
      end
    end
  end
end
