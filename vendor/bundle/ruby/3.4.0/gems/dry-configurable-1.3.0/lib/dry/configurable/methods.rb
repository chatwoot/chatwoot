# frozen_string_literal: true

module Dry
  module Configurable
    # Common API for both classes and instances
    #
    # @api public
    module Methods
      # @api public
      def configure(&block)
        raise FrozenConfigError, "Cannot modify frozen config" if config.frozen?

        yield(config) if block
        self
      end

      # Finalize and freeze configuration
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def finalize!(freeze_values: false)
        config.finalize!(freeze_values: freeze_values)
        self
      end
    end
  end
end
