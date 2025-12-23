# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Access modifiers should be declared to apply to a group of methods
      # or inline before each method, depending on configuration.
      # EnforcedStyle config covers only method definitions.
      # Applications of visibility methods to symbols can be controlled
      # using AllowModifiersOnSymbols config.
      # Also, the visibility of `attr*` methods can be controlled using
      # AllowModifiersOnAttrs config.
      #
      # In Ruby 3.0, `attr*` methods now return an array of defined method names
      # as symbols. So we can write the modifier and `attr*` in inline style.
      # AllowModifiersOnAttrs config allows `attr*` methods to be written in
      # inline style without modifying applications that have been maintained
      # for a long time in group style. Furthermore, developers who are not very
      # familiar with Ruby may know that the modifier applies to `def`, but they
      # may not know that it also applies to `attr*` methods. It would be easier
      # to understand if we could write `attr*` methods in inline style.
      #
      # @safety
      #   Autocorrection is not safe, because the visibility of dynamically
      #   defined methods can vary depending on the state determined by
      #   the group access modifier.
      #
      # @example EnforcedStyle: group (default)
      #   # bad
      #   class Foo
      #
      #     private def bar; end
      #     private def baz; end
      #
      #   end
      #
      #   # good
      #   class Foo
      #
      #     private
      #
      #     def bar; end
      #     def baz; end
      #
      #   end
      #
      # @example EnforcedStyle: inline
      #   # bad
      #   class Foo
      #
      #     private
      #
      #     def bar; end
      #     def baz; end
      #
      #   end
      #
      #   # good
      #   class Foo
      #
      #     private def bar; end
      #     private def baz; end
      #
      #   end
      #
      # @example AllowModifiersOnSymbols: true (default)
      #   # good
      #   class Foo
      #
      #     private :bar, :baz
      #     private *%i[qux quux]
      #     private *METHOD_NAMES
      #     private *private_methods
      #
      #   end
      #
      # @example AllowModifiersOnSymbols: false
      #   # bad
      #   class Foo
      #
      #     private :bar, :baz
      #     private *%i[qux quux]
      #     private *METHOD_NAMES
      #     private *private_methods
      #
      #   end
      #
      # @example AllowModifiersOnAttrs: true (default)
      #   # good
      #   class Foo
      #
      #     public attr_reader :bar
      #     protected attr_writer :baz
      #     private attr_accessor :qux
      #     private attr :quux
      #
      #     def public_method; end
      #
      #     private
      #
      #     def private_method; end
      #
      #   end
      #
      # @example AllowModifiersOnAttrs: false
      #   # bad
      #   class Foo
      #
      #     public attr_reader :bar
      #     protected attr_writer :baz
      #     private attr_accessor :qux
      #     private attr :quux
      #
      #   end
      #
      # @example AllowModifiersOnAliasMethod: true (default)
      #   # good
      #   class Foo
      #
      #     public alias_method :bar, :foo
      #     protected alias_method :baz, :foo
      #     private alias_method :qux, :foo
      #
      #   end
      #
      # @example AllowModifiersOnAliasMethod: false
      #   # bad
      #   class Foo
      #
      #     public alias_method :bar, :foo
      #     protected alias_method :baz, :foo
      #     private alias_method :qux, :foo
      #
      #   end
      class AccessModifierDeclarations < Base
        extend AutoCorrector

        include ConfigurableEnforcedStyle
        include RangeHelp

        GROUP_STYLE_MESSAGE = [
          '`%<access_modifier>s` should not be',
          'inlined in method definitions.'
        ].join(' ')

        INLINE_STYLE_MESSAGE = [
          '`%<access_modifier>s` should be',
          'inlined in method definitions.'
        ].join(' ')

        RESTRICT_ON_SEND = %i[private protected public module_function].freeze

        # @!method access_modifier_with_symbol?(node)
        def_node_matcher :access_modifier_with_symbol?, <<~PATTERN
          (send nil? {:private :protected :public :module_function}
            {(sym _)+ (splat {#percent_symbol_array? const send})}
          )
        PATTERN

        # @!method access_modifier_with_attr?(node)
        def_node_matcher :access_modifier_with_attr?, <<~PATTERN
          (send nil? {:private :protected :public :module_function}
            (send nil? {:attr :attr_reader :attr_writer :attr_accessor} _+))
        PATTERN

        # @!method access_modifier_with_alias_method?, <<~PATTERN
        def_node_matcher :access_modifier_with_alias_method?, <<~PATTERN
          (send nil? {:private :protected :public :module_function}
            (send nil? :alias_method _ _))
        PATTERN

        def on_send(node)
          return if allowed?(node)

          if offense?(node)
            add_offense(node.loc.selector) do |corrector|
              autocorrect(corrector, node)
            end
            opposite_style_detected
          else
            correct_style_detected
          end
        end

        private

        def allowed?(node)
          !node.access_modifier? ||
            node.parent&.type?(:pair, :any_block) ||
            allow_modifiers_on_symbols?(node) ||
            allow_modifiers_on_attrs?(node) ||
            allow_modifiers_on_alias_method?(node)
        end

        def autocorrect(corrector, node)
          case style
          when :group
            def_nodes = find_corresponding_def_nodes(node)
            return unless def_nodes.any?

            replace_defs(corrector, node, def_nodes)
          when :inline
            remove_nodes(corrector, node)
            select_grouped_def_nodes(node).each do |grouped_def_node|
              insert_inline_modifier(corrector, grouped_def_node, node.method_name)
            end
          end
        end

        def percent_symbol_array?(node)
          node.array_type? && node.percent_literal?(:symbol)
        end

        def allow_modifiers_on_symbols?(node)
          cop_config['AllowModifiersOnSymbols'] && access_modifier_with_symbol?(node)
        end

        def allow_modifiers_on_attrs?(node)
          cop_config['AllowModifiersOnAttrs'] && access_modifier_with_attr?(node)
        end

        def allow_modifiers_on_alias_method?(node)
          cop_config['AllowModifiersOnAliasMethod'] && access_modifier_with_alias_method?(node)
        end

        def offense?(node)
          (group_style? && access_modifier_is_inlined?(node) &&
            !node.parent&.if_type? && !right_siblings_same_inline_method?(node)) ||
            (inline_style? && access_modifier_is_not_inlined?(node))
        end

        def correctable_group_offense?(node)
          return false unless group_style?
          return false if allowed?(node)

          access_modifier_is_inlined?(node) && find_corresponding_def_nodes(node).any?
        end

        def group_style?
          style == :group
        end

        def inline_style?
          style == :inline
        end

        def access_modifier_is_inlined?(node)
          node.arguments.any?
        end

        def access_modifier_is_not_inlined?(node)
          !access_modifier_is_inlined?(node)
        end

        def right_siblings_same_inline_method?(node)
          node.right_siblings.any? do |sibling|
            sibling.send_type? &&
              correctable_group_offense?(sibling) &&
              sibling.method?(node.method_name) &&
              !sibling.arguments.empty? &&
              find_corresponding_def_nodes(sibling).any?
          end
        end

        def message(range)
          access_modifier = range.source

          if group_style?
            format(GROUP_STYLE_MESSAGE, access_modifier: access_modifier)
          elsif inline_style?
            format(INLINE_STYLE_MESSAGE, access_modifier: access_modifier)
          end
        end

        def find_corresponding_def_nodes(node)
          if access_modifier_with_symbol?(node)
            method_names = node.arguments.filter_map do |argument|
              next unless argument.sym_type?

              argument.respond_to?(:value) && argument.value
            end

            def_nodes = node.parent.each_child_node(:def).select do |child|
              method_names.include?(child.method_name)
            end

            # If there isn't a `def` node for each symbol, we will skip autocorrection.
            def_nodes.size == method_names.size ? def_nodes : []
          else
            [node.first_argument]
          end
        end

        def find_argument_less_modifier_node(node)
          return unless (parent = node.parent)

          parent.each_child_node(:send).find do |child|
            child.method?(node.method_name) && child.arguments.empty?
          end
        end

        def select_grouped_def_nodes(node)
          node.right_siblings.take_while do |sibling|
            !(sibling.send_type? && sibling.bare_access_modifier_declaration?)
          end.select(&:def_type?)
        end

        def replace_defs(corrector, node, def_nodes)
          source = def_source(node, def_nodes)
          argument_less_modifier_node = find_argument_less_modifier_node(node)
          if argument_less_modifier_node
            corrector.insert_after(argument_less_modifier_node, "\n\n#{source}")
          elsif (ancestor = node.each_ancestor(:class, :module).first)

            corrector.insert_before(ancestor.loc.end, "#{node.method_name}\n\n#{source}\n")
          else
            corrector.replace(node, "#{node.method_name}\n\n#{source}")
            return
          end

          remove_nodes(corrector, *def_nodes, node)
        end

        def insert_inline_modifier(corrector, node, modifier_name)
          corrector.insert_before(node, "#{modifier_name} ")
        end

        def remove_nodes(corrector, *nodes)
          nodes.each do |node|
            corrector.remove(range_with_comments_and_lines(node))
          end
        end

        def def_source(node, def_nodes)
          [
            *processed_source.ast_with_comments[node].map(&:text),
            *def_nodes.map(&:source)
          ].join("\n")
        end
      end
    end
  end
end
