# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for `attribute` class methods that specify a `:default` option
      # which value is an array, string literal or method call without a block.
      # It will accept all other values, such as string, symbol, integer and float literals
      # as well as constants.
      #
      # @example
      #   # bad
      #   class User < ApplicationRecord
      #     attribute :confirmed_at, :datetime, default: Time.zone.now
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     attribute :confirmed_at, :datetime, default: -> { Time.zone.now }
      #   end
      #
      #   # bad
      #   class User < ApplicationRecord
      #     attribute :roles, :string, array: true, default: []
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     attribute :roles, :string, array: true, default: -> { [] }
      #   end
      #
      #   # bad
      #   class User < ApplicationRecord
      #     attribute :configuration, default: {}
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     attribute :configuration, default: -> { {} }
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     attribute :role, :string, default: :customer
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     attribute :activated, :boolean, default: false
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     attribute :login_count, :integer, default: 0
      #   end
      #
      #   # good
      #   class User < ApplicationRecord
      #     FOO = 123
      #     attribute :custom_attribute, :integer, default: FOO
      #   end
      class AttributeDefaultBlockValue < Base
        extend AutoCorrector

        MSG = 'Pass method in a block to `:default` option.'
        RESTRICT_ON_SEND = %i[attribute].freeze
        TYPE_OFFENDERS = %i[send array hash].freeze

        def_node_matcher :default_attribute, <<~PATTERN
          (send nil? :attribute _ ?_ (hash <$#attribute ...>))
        PATTERN

        def_node_matcher :attribute, '(pair (sym :default) $_)'

        def on_send(node)
          default_attribute(node) do |attribute|
            value = attribute.children.last
            return unless TYPE_OFFENDERS.any?(value.type)

            add_offense(value) do |corrector|
              expression = default_attribute(node).children.last

              corrector.replace(value, "-> { #{expression.source} }")
            end
          end
        end
      end
    end
  end
end
