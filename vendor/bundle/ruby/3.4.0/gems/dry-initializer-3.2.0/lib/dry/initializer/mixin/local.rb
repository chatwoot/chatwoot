# frozen_string_literal: true

module Dry
  module Initializer
    module Mixin
      # @private
      module Local
        attr_reader :klass

        def inspect
          "Dry::Initializer::Mixin::Local[#{klass}]"
        end
        alias_method :to_s, :inspect
        alias_method :to_str, :inspect

        private

        def included(klass)
          @klass = klass
          super
        end
      end
    end
  end
end
