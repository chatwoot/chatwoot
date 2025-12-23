# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks if the value of the option `class_name`, in
      # the definition of a reflection is a string.
      #
      # @safety
      #   This cop is unsafe because it cannot be determined whether
      #   constant or method return value specified to `class_name` is a string.
      #
      # @example
      #   # bad
      #   has_many :accounts, class_name: Account
      #   has_many :accounts, class_name: Account.name
      #
      #   # good
      #   has_many :accounts, class_name: 'Account'
      class ReflectionClassName < Base
        extend AutoCorrector

        MSG = 'Use a string value for `class_name`.'
        RESTRICT_ON_SEND = %i[has_many has_one belongs_to].freeze
        ALLOWED_REFLECTION_CLASS_TYPES = %i[dstr str sym].freeze

        def_node_matcher :association_with_reflection, <<~PATTERN
          (send nil? {:has_many :has_one :belongs_to} _ _ ?
            (hash <$#reflection_class_name ...>)
          )
        PATTERN

        def_node_matcher :reflection_class_name, <<~PATTERN
          (pair (sym :class_name) #reflection_class_value?)
        PATTERN

        def_node_matcher :const_or_string, <<~PATTERN
          {$(const nil? _) (send $(const nil? _) :name) (send $(const nil? _) :to_s)}
        PATTERN

        def on_send(node)
          association_with_reflection(node) do |reflection_class_name|
            return if reflection_class_name.value.send_type? && !reflection_class_name.value.receiver&.const_type?
            return if reflection_class_name.value.lvar_type? && str_assigned?(reflection_class_name)

            add_offense(reflection_class_name) do |corrector|
              autocorrect(corrector, reflection_class_name)
            end
          end
        end

        private

        def str_assigned?(reflection_class_name)
          lvar = reflection_class_name.value.source

          reflection_class_name.ancestors.each do |nodes|
            return true if nodes.each_child_node(:lvasgn).detect do |node|
              lhs, rhs = *node

              lhs.to_s == lvar && ALLOWED_REFLECTION_CLASS_TYPES.include?(rhs.type)
            end
          end

          false
        end

        def reflection_class_value?(class_value)
          if class_value.send_type?
            !class_value.method?(:to_s) || class_value.receiver&.const_type?
          else
            !ALLOWED_REFLECTION_CLASS_TYPES.include?(class_value.type)
          end
        end

        def autocorrect(corrector, class_config)
          class_value = class_config.value
          replacement = const_or_string(class_value)
          return unless replacement

          corrector.replace(class_value, replacement.source.inspect)
        end
      end
    end
  end
end
