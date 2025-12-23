# frozen_string_literal: true

module Dry
  module Initializer
    # @private
    module Mixin
      extend  DSL              # @deprecated
      include Dry::Initializer # @deprecated
      # @deprecated
      def self.extended(klass)
        warn "[DEPRECATED] Use Dry::Initializer instead of its alias" \
             " Dry::Initializer::Mixin. The later will be removed in v2.1.0"
        super
      end

      require_relative "mixin/root"
      require_relative "mixin/local"
    end
  end
end
