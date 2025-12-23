# frozen_string_literal: true

require "dry/core/container"
require "dry/types"

module Dry
  module Schema
    # A class to build containers for custom types, which can be used in schemas
    #
    # @example
    #   MyTypeContainer = Dry::Schema::TypeContainer.new
    #   MyTypeContainer.register('params.fancy_string', Types::FancyString)
    #
    # @api public
    class TypeContainer
      include ::Dry::Core::Container::Mixin

      def initialize(types_container = ::Dry::Types.container)
        super()

        merge(types_container)
      end

      alias_method :registered?, :key?
    end
  end
end
