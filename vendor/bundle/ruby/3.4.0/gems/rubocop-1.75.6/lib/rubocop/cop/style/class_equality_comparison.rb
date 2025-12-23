# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of `Object#instance_of?` instead of class comparison
      # for equality.
      # `==`, `equal?`, and `eql?` custom method definitions are allowed by default.
      # These are customizable with `AllowedMethods` option.
      #
      # @safety
      #   This cop's autocorrection is unsafe because there is no guarantee that
      #   the constant `Foo` exists when autocorrecting `var.class.name == 'Foo'` to
      #   `var.instance_of?(Foo)`.
      #
      # @example
      #   # bad
      #   var.class == Date
      #   var.class.equal?(Date)
      #   var.class.eql?(Date)
      #   var.class.name == 'Date'
      #
      #   # good
      #   var.instance_of?(Date)
      #
      # @example AllowedMethods: ['==', 'equal?', 'eql?'] (default)
      #   # good
      #   def ==(other)
      #     self.class == other.class && name == other.name
      #   end
      #
      #   def equal?(other)
      #     self.class.equal?(other.class) && name.equal?(other.name)
      #   end
      #
      #   def eql?(other)
      #     self.class.eql?(other.class) && name.eql?(other.name)
      #   end
      #
      # @example AllowedPatterns: [] (default)
      #   # bad
      #   def eq(other)
      #     self.class.eq(other.class) && name.eq(other.name)
      #   end
      #
      # @example AllowedPatterns: ['eq']
      #   # good
      #   def eq(other)
      #     self.class.eq(other.class) && name.eq(other.name)
      #   end
      #
      class ClassEqualityComparison < Base
        include RangeHelp
        include AllowedMethods
        include AllowedPattern
        extend AutoCorrector

        MSG = 'Use `instance_of?%<class_argument>s` instead of comparing classes.'

        RESTRICT_ON_SEND = %i[== equal? eql?].freeze
        CLASS_NAME_METHODS = %i[name to_s inspect].freeze

        # @!method class_comparison_candidate?(node)
        def_node_matcher :class_comparison_candidate?, <<~PATTERN
          (send
            {$(send _ :class) (send $(send _ :class) #class_name_method?)}
            {:== :equal? :eql?} $_)
        PATTERN

        def on_send(node)
          def_node = node.each_ancestor(:any_def).first
          return if def_node &&
                    (allowed_method?(def_node.method_name) ||
                    matches_allowed_pattern?(def_node.method_name))

          class_comparison_candidate?(node) do |receiver_node, class_node|
            return if class_node.dstr_type?

            range = offense_range(receiver_node, node)
            class_argument = (class_name = class_name(class_node, node)) ? "(#{class_name})" : ''

            add_offense(range, message: format(MSG, class_argument: class_argument)) do |corrector|
              next unless class_name

              corrector.replace(range, "instance_of?#{class_argument}")
            end
          end
        end

        private

        def class_name(class_node, node)
          if class_name_method?(node.children.first.method_name)
            if (receiver = class_node.receiver) && class_name_method?(class_node.method_name)
              return receiver.source
            end

            if class_node.str_type?
              value = trim_string_quotes(class_node)
              value.prepend('::') if require_cbase?(class_node)
              return value
            elsif unable_to_determine_type?(class_node)
              # When a variable or return value of a method is used, it returns nil
              # because the type is not known and cannot be suggested.
              return
            end
          end

          class_node.source
        end

        def class_name_method?(method_name)
          CLASS_NAME_METHODS.include?(method_name)
        end

        def require_cbase?(class_node)
          class_node.each_ancestor(:class, :module).any?
        end

        def unable_to_determine_type?(class_node)
          class_node.variable? || class_node.call_type?
        end

        def trim_string_quotes(class_node)
          class_node.source.delete('"').delete("'")
        end

        def offense_range(receiver_node, node)
          range_between(receiver_node.loc.selector.begin_pos, node.source_range.end_pos)
        end
      end
    end
  end
end
