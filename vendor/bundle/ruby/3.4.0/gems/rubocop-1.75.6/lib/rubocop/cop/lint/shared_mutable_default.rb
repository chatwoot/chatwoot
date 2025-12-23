# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for `Hash` creation with a mutable default value.
      # Creating a `Hash` in such a way will share the default value
      # across all keys, causing unexpected behavior when modifying it.
      #
      # For example, when the `Hash` was created with an `Array` as the argument,
      # calling `hash[:foo] << 'bar'` will also change the value of all
      # other keys that have not been explicitly assigned to.
      #
      # @example
      #   # bad
      #   Hash.new([])
      #   Hash.new({})
      #   Hash.new(Array.new)
      #   Hash.new(Hash.new)
      #
      #   # okay -- In rare cases that intentionally have this behavior,
      #   #   without disabling the cop, you can set the default explicitly.
      #   h = Hash.new
      #   h.default = []
      #   h[:a] << 1
      #   h[:b] << 2
      #   h # => {:a => [1, 2], :b => [1, 2]}
      #
      #   # okay -- beware this will discard mutations and only remember assignments
      #   Hash.new { Array.new }
      #   Hash.new { Hash.new }
      #   Hash.new { {} }
      #   Hash.new { [] }
      #
      #   # good - frozen solution will raise an error when mutation attempted
      #   Hash.new([].freeze)
      #   Hash.new({}.freeze)
      #
      #   # good - using a proc will create a new object for each key
      #   h = Hash.new
      #   h.default_proc = ->(h, k) { [] }
      #   h.default_proc = ->(h, k) { {} }
      #
      #   # good - using a block will create a new object for each key
      #   Hash.new { |h, k| h[k] = [] }
      #   Hash.new { |h, k| h[k] = {} }
      class SharedMutableDefault < Base
        MSG = 'Do not create a Hash with a mutable default value ' \
              'as the default value can accidentally be changed.'
        RESTRICT_ON_SEND = %i[new].freeze

        # @!method hash_initialized_with_mutable_shared_object?(node)
        def_node_matcher :hash_initialized_with_mutable_shared_object?, <<~PATTERN
          {
            (send (const {nil? cbase} :Hash) :new [
              {array hash (send (const {nil? cbase} {:Array :Hash}) :new)}
              !#capacity_keyword_argument?
            ])
            (send (const {nil? cbase} :Hash) :new hash #capacity_keyword_argument?)
          }
        PATTERN

        # @!method capacity_keyword_argument?(node)
        def_node_matcher :capacity_keyword_argument?, <<~PATTERN
          (hash (pair (sym :capacity) _))
        PATTERN

        def on_send(node)
          return unless hash_initialized_with_mutable_shared_object?(node)

          add_offense(node)
        end
      end
    end
  end
end
