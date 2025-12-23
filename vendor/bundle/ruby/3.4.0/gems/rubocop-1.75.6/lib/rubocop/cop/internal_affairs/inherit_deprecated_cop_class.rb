# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # `RuboCop::Cop::Cop` is deprecated and will be removed in RuboCop 2.0.
      # Your custom cop class should inherit from `RuboCop::Cop::Base` instead of
      # `RuboCop::Cop::Cop`.
      #
      # See "v1 Upgrade Notes" for more details:
      # https://docs.rubocop.org/rubocop/v1_upgrade_notes.html
      #
      # @example
      #   # bad
      #   class Foo < Cop
      #   end
      #
      #   # good
      #   class Foo < Base
      #   end
      #
      class InheritDeprecatedCopClass < Base
        MSG = 'Use `Base` instead of `Cop`.'

        def on_class(node)
          return unless (parent_class = node.parent_class)
          return unless parent_class.children.last == :Cop

          add_offense(parent_class)
        end
      end
    end
  end
end
