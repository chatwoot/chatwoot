# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces the use of dot-separated locale keys instead of specifying the `:scope` option
      # with an array or a single symbol in `I18n` translation methods.
      # Dot-separated notation is easier to read and trace the hierarchy.
      #
      # @example
      #   # bad
      #   I18n.t :record_invalid, scope: [:activerecord, :errors, :messages]
      #   I18n.t :title, scope: :invitation
      #
      #   # good
      #   I18n.t 'activerecord.errors.messages.record_invalid'
      #   I18n.t :record_invalid, scope: 'activerecord.errors.messages'
      #
      class DotSeparatedKeys < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use the dot-separated keys instead of specifying the `:scope` option.'
        TRANSLATE_METHODS = %i[translate t].freeze

        def_node_matcher :translate_with_scope?, <<~PATTERN
          (send {nil? (const {nil? cbase} :I18n)} {:translate :t} ${sym_type? str_type?}
            (hash <$(pair (sym :scope) ${array_type? sym_type?}) ...>)
          )
        PATTERN

        def on_send(node)
          return unless TRANSLATE_METHODS.include?(node.method_name)

          translate_with_scope?(node) do |key_node, scope_node|
            return unless should_convert_scope?(scope_node)

            add_offense(scope_node) do |corrector|
              # Eat the comma on the left.
              range = range_with_surrounding_space(scope_node.source_range, side: :left)
              range = range_with_surrounding_comma(range, :left)
              corrector.remove(range)

              corrector.replace(key_node, new_key(key_node, scope_node))
            end
          end
        end

        private

        def should_convert_scope?(scope_node)
          scopes(scope_node).all?(&:basic_literal?)
        end

        def new_key(key_node, scope_node)
          "'#{scopes(scope_node).map(&:value).join('.')}.#{key_node.value}'".squeeze('.')
        end

        def scopes(scope_node)
          value = scope_node.value

          if value.array_type?
            value.values
          else
            [value]
          end
        end
      end
    end
  end
end
