# frozen_string_literal: true

module Dry
  module Core
    # Thread-safe object registry
    #
    # @example
    #
    #   container = Dry::Core::Container.new
    #   container.register(:item, 'item')
    #   container.resolve(:item)
    #   => 'item'
    #
    #   container.register(:item1, -> { 'item' })
    #   container.resolve(:item1)
    #   => 'item'
    #
    #   container.register(:item2, -> { 'item' }, call: false)
    #   container.resolve(:item2)
    #   => #<Proc:0x007f33b169e998@(irb):10 (lambda)>
    #
    # @api public
    class Container
      include Container::Mixin
    end
  end
end
