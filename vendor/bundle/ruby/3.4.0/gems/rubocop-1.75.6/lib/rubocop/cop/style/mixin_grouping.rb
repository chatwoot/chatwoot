# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for grouping of mixins in `class` and `module` bodies.
      # By default it enforces mixins to be placed in separate declarations,
      # but it can be configured to enforce grouping them in one declaration.
      #
      # @example EnforcedStyle: separated (default)
      #   # bad
      #   class Foo
      #     include Bar, Qox
      #   end
      #
      #   # good
      #   class Foo
      #     include Qox
      #     include Bar
      #   end
      #
      # @example EnforcedStyle: grouped
      #   # bad
      #   class Foo
      #     extend Bar
      #     extend Qox
      #   end
      #
      #   # good
      #   class Foo
      #     extend Qox, Bar
      #   end
      class MixinGrouping < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MIXIN_METHODS = %i[extend include prepend].freeze
        MSG = 'Put `%<mixin>s` mixins in %<suffix>s.'

        def on_class(node)
          begin_node = node.child_nodes.find(&:begin_type?) || node
          begin_node.each_child_node(:send).select(&:macro?).each do |macro|
            next if !MIXIN_METHODS.include?(macro.method_name) || macro.arguments.empty?

            check(macro)
          end
        end

        alias on_module on_class

        private

        def range_to_remove_for_subsequent_mixin(mixins, node)
          range = node.source_range
          prev_mixin = mixins.each_cons(2) { |m, n| break m if n == node }
          between = prev_mixin.source_range.end.join(range.begin)
          # if separated from previous mixin with only whitespace?
          unless /\S/.match?(between.source)
            range = range.join(between) # then remove that too
          end
          range
        end

        def check(send_node)
          if separated_style?
            check_separated_style(send_node)
          else
            check_grouped_style(send_node)
          end
        end

        def check_grouped_style(send_node)
          return if sibling_mixins(send_node).size == 1

          message = format(MSG, mixin: send_node.method_name, suffix: 'a single statement')

          add_offense(send_node, message: message) do |corrector|
            range = send_node.source_range
            mixins = sibling_mixins(send_node)
            if send_node == mixins.first
              correction = group_mixins(send_node, mixins)
            else
              range = range_to_remove_for_subsequent_mixin(mixins, send_node)
              correction = ''
            end

            corrector.replace(range, correction)
          end
        end

        def check_separated_style(send_node)
          return if send_node.arguments.one?

          message = format(MSG, mixin: send_node.method_name, suffix: 'separate statements')

          add_offense(send_node, message: message) do |corrector|
            range = send_node.source_range
            correction = separate_mixins(send_node)

            corrector.replace(range, correction)
          end
        end

        def sibling_mixins(send_node)
          siblings = send_node.parent.each_child_node(:send).select(&:macro?)

          siblings.select { |sibling_node| sibling_node.method?(send_node.method_name) }
        end

        def grouped_style?
          style == :grouped
        end

        def separated_style?
          style == :separated
        end

        def separate_mixins(node)
          arguments = node.arguments.reverse
          mixins = ["#{node.method_name} #{arguments.first.source}"]

          arguments[1..].inject(mixins) do |replacement, arg|
            replacement << "#{indent(node)}#{node.method_name} #{arg.source}"
          end.join("\n")
        end

        def group_mixins(node, mixins)
          mixin_names = mixins.reverse.flat_map { |mixin| mixin.arguments.map(&:source) }

          "#{node.method_name} #{mixin_names.join(', ')}"
        end
      end
    end
  end
end
