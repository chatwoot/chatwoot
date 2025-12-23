# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces using `def self.method_name` or `class << self` to define class methods.
      #
      # @example EnforcedStyle: def_self (default)
      #   # bad
      #   class SomeClass
      #     class << self
      #       attr_accessor :class_accessor
      #
      #       def class_method
      #         # ...
      #       end
      #     end
      #   end
      #
      #   # good
      #   class SomeClass
      #     def self.class_method
      #       # ...
      #     end
      #
      #     class << self
      #       attr_accessor :class_accessor
      #     end
      #   end
      #
      #   # good - contains private method
      #   class SomeClass
      #     class << self
      #       attr_accessor :class_accessor
      #
      #       private
      #
      #       def private_class_method
      #         # ...
      #       end
      #     end
      #   end
      #
      # @example EnforcedStyle: self_class
      #   # bad
      #   class SomeClass
      #     def self.class_method
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   class SomeClass
      #     class << self
      #       def class_method
      #         # ...
      #       end
      #     end
      #   end
      #
      class ClassMethodsDefinitions < Base
        include ConfigurableEnforcedStyle
        include CommentsHelp
        include VisibilityHelp
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<preferred>s` to define a class method.'
        MSG_SCLASS = 'Do not define public methods within class << self.'

        def on_sclass(node)
          return unless def_self_style?
          return unless node.identifier.self_type?
          return unless all_methods_public?(node)

          add_offense(node, message: MSG_SCLASS) do |corrector|
            autocorrect_sclass(node, corrector)
          end
        end

        def on_defs(node)
          return if def_self_style?
          return unless node.receiver.self_type?

          message = format(MSG, preferred: 'class << self')
          add_offense(node, message: message)
        end

        private

        def def_self_style?
          style == :def_self
        end

        def all_methods_public?(sclass_node)
          def_nodes = def_nodes(sclass_node)
          return false if def_nodes.empty?

          def_nodes.all? { |def_node| node_visibility(def_node) == :public }
        end

        def def_nodes(sclass_node)
          sclass_def = sclass_node.body
          return [] unless sclass_def

          if sclass_def.def_type?
            [sclass_def]
          elsif sclass_def.begin_type?
            sclass_def.each_child_node(:def).to_a
          else
            []
          end
        end

        def autocorrect_sclass(node, corrector)
          rewritten_defs = []

          def_nodes(node).each do |def_node|
            next unless node_visibility(def_node) == :public

            range, source = extract_def_from_sclass(def_node, node)

            corrector.remove(range)
            rewritten_defs << source
          end

          if sclass_only_has_methods?(node)
            corrector.remove(node)
            rewritten_defs.first&.strip!
          else
            corrector.insert_after(node, "\n")
          end

          corrector.insert_after(node, rewritten_defs.join("\n"))
        end

        def sclass_only_has_methods?(node)
          node.body.def_type? || node.body.each_child_node.all?(&:def_type?)
        end

        def extract_def_from_sclass(def_node, sclass_node)
          range = source_range_with_comment(def_node)
          source = range.source.sub!(
            "def #{def_node.method_name}",
            "def self.#{def_node.method_name}"
          )

          source = source.gsub(/^ {#{indentation_diff(def_node, sclass_node)}}/, '')
          [range, source.chomp]
        end

        def indentation_diff(node1, node2)
          node1.loc.column - node2.loc.column
        end
      end
    end
  end
end
