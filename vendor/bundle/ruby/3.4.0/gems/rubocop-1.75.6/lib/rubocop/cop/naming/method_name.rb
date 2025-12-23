# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Makes sure that all methods use the configured style,
      # snake_case or camelCase, for their names.
      #
      # Method names matching patterns are always allowed.
      #
      # The cop can be configured with `AllowedPatterns` to allow certain regexp patterns:
      #
      # [source,yaml]
      # ----
      # Naming/MethodName:
      #   AllowedPatterns:
      #     - '\AonSelectionBulkChange\z'
      #     - '\AonSelectionCleared\z'
      # ----
      #
      # As well, you can also forbid specific method names or regexp patterns
      # using `ForbiddenIdentifiers` or `ForbiddenPatterns`:
      #
      # [source,yaml]
      # ----
      # Naming/MethodName:
      #   ForbiddenIdentifiers:
      #     - 'def'
      #     - 'super'
      #   ForbiddenPatterns:
      #     - '_v1\z'
      #     - '_gen1\z'
      # ----
      #
      # @example EnforcedStyle: snake_case (default)
      #   # bad
      #   def fooBar; end
      #
      #   # good
      #   def foo_bar; end
      #
      # @example EnforcedStyle: camelCase
      #   # bad
      #   def foo_bar; end
      #
      #   # good
      #   def fooBar; end
      #
      # @example ForbiddenIdentifiers: ['def', 'super']
      #   # bad
      #   def def; end
      #   def super; end
      #
      # @example ForbiddenPatterns: ['_v1\z', '_gen1\z']
      #   # bad
      #   def release_v1; end
      #   def api_gen1; end
      #
      class MethodName < Base
        include ConfigurableNaming
        include AllowedPattern
        include RangeHelp
        include ForbiddenIdentifiers
        include ForbiddenPattern

        MSG = 'Use %<style>s for method names.'
        MSG_FORBIDDEN = '`%<identifier>s` is forbidden, use another method name instead.'

        # @!method sym_name(node)
        def_node_matcher :sym_name, '(sym $_name)'

        # @!method str_name(node)
        def_node_matcher :str_name, '(str $_name)'

        def on_send(node)
          return unless (attrs = node.attribute_accessor?)

          attrs.last.each do |name_item|
            name = attr_name(name_item)
            next if !name || matches_allowed_pattern?(name)

            if forbidden_name?(name.to_s)
              register_forbidden_name(node)
            else
              check_name(node, name, range_position(node))
            end
          end
        end

        def on_def(node)
          return if node.operator_method? || matches_allowed_pattern?(node.method_name)

          if forbidden_name?(node.method_name.to_s)
            register_forbidden_name(node)
          else
            check_name(node, node.method_name, node.loc.name)
          end
        end
        alias on_defs on_def

        private

        def forbidden_name?(name)
          forbidden_identifier?(name) || forbidden_pattern?(name)
        end

        def register_forbidden_name(node)
          if node.any_def_type?
            name_node = node.loc.name
            method_name = node.method_name
          else
            attrs = node.attribute_accessor?
            name_node = attrs.last.last
            method_name = attr_name(name_node)
          end
          message = format(MSG_FORBIDDEN, identifier: method_name)
          add_offense(name_node, message: message)
        end

        def attr_name(name_item)
          sym_name(name_item) || str_name(name_item)
        end

        def range_position(node)
          selector_end_pos = node.loc.selector.end_pos + 1
          expr_end_pos = node.source_range.end_pos

          range_between(selector_end_pos, expr_end_pos)
        end

        def message(style)
          format(MSG, style: style)
        end
      end
    end
  end
end
