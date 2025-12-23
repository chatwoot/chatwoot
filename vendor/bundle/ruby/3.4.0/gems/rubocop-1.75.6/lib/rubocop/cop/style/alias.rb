# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of either `#alias` or `#alias_method`
      # depending on configuration.
      # It also flags uses of `alias :symbol` rather than `alias bareword`.
      #
      # However, it will always enforce `method_alias` when used `alias`
      # in an instance method definition and in a singleton method definition.
      # If used in a block, always enforce `alias_method`
      # unless it is an `instance_eval` block.
      #
      # @example EnforcedStyle: prefer_alias (default)
      #   # bad
      #   alias_method :bar, :foo
      #   alias :bar :foo
      #
      #   # good
      #   alias bar foo
      #
      # @example EnforcedStyle: prefer_alias_method
      #   # bad
      #   alias :bar :foo
      #   alias bar foo
      #
      #   # good
      #   alias_method :bar, :foo
      #
      class Alias < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG_ALIAS = 'Use `alias_method` instead of `alias`.'
        MSG_ALIAS_METHOD = 'Use `alias` instead of `alias_method` %<current>s.'
        MSG_SYMBOL_ARGS  = 'Use `alias %<prefer>s` instead of `alias %<current>s`.'

        RESTRICT_ON_SEND = %i[alias_method].freeze

        def on_send(node)
          return unless node.command?(:alias_method)
          return unless style == :prefer_alias && alias_keyword_possible?(node)
          return unless node.arguments.count == 2

          msg = format(MSG_ALIAS_METHOD, current: lexical_scope_type(node))
          add_offense(node.loc.selector, message: msg) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def on_alias(node)
          return unless alias_method_possible?(node)

          if scope_type(node) == :dynamic || style == :prefer_alias_method
            add_offense(node.loc.keyword, message: MSG_ALIAS) do |corrector|
              autocorrect(corrector, node)
            end
          elsif node.children.none? { |arg| bareword?(arg) }
            add_offense_for_args(node) { |corrector| autocorrect(corrector, node) }
          end
        end

        private

        def autocorrect(corrector, node)
          if node.send_type?
            correct_alias_method_to_alias(corrector, node)
          elsif scope_type(node) == :dynamic || style == :prefer_alias_method
            correct_alias_to_alias_method(corrector, node)
          else
            correct_alias_with_symbol_args(corrector, node)
          end
        end

        def alias_keyword_possible?(node)
          scope_type(node) != :dynamic && node.arguments.all?(&:sym_type?)
        end

        def alias_method_possible?(node)
          scope_type(node) != :instance_eval &&
            node.children.none?(&:gvar_type?) &&
            node.each_ancestor(:def).none?
        end

        def add_offense_for_args(node, &block)
          existing_args  = node.children.map(&:source).join(' ')
          preferred_args = node.children.map { |a| a.source[1..] }.join(' ')
          arg_ranges     = node.children.map(&:source_range)
          msg            = format(MSG_SYMBOL_ARGS, prefer: preferred_args, current: existing_args)
          add_offense(arg_ranges.reduce(&:join), message: msg, &block)
        end

        # In this expression, will `self` be the same as the innermost enclosing
        # class or module block (:lexical)? Or will it be something else
        # (:dynamic)? If we're in an instance_eval block, return that.
        def scope_type(node)
          while (parent = node.parent)
            case parent.type
            when :class, :module
              return :lexical
            when :def, :defs
              return :dynamic
            when :block
              return :instance_eval if parent.method?(:instance_eval)

              return :dynamic
            end
            node = parent
          end
          :lexical
        end

        def lexical_scope_type(node)
          ancestor = node.each_ancestor(:class, :module).first
          if ancestor.nil?
            'at the top level'
          elsif ancestor.class_type?
            'in a class body'
          else
            'in a module body'
          end
        end

        def bareword?(sym_node)
          !sym_node.source.start_with?(':') || sym_node.dsym_type?
        end

        def correct_alias_method_to_alias(corrector, send_node)
          new, old = *send_node.arguments
          replacement = "alias #{identifier(new)} #{identifier(old)}"

          corrector.replace(send_node, replacement)
        end

        def correct_alias_to_alias_method(corrector, node)
          replacement =
            "alias_method #{identifier(node.new_identifier)}, #{identifier(node.old_identifier)}"

          corrector.replace(node, replacement)
        end

        def correct_alias_with_symbol_args(corrector, node)
          corrector.replace(node.new_identifier, node.new_identifier.source[1..])
          corrector.replace(node.old_identifier, node.old_identifier.source[1..])
        end

        def identifier(node)
          if node.sym_type?
            ":#{node.children.first}"
          else
            node.source
          end
        end
      end
    end
  end
end
