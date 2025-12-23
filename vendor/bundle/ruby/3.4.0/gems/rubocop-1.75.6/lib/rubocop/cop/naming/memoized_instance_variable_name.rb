# frozen_string_literal: true

module RuboCop
  module Cop
    module Naming
      # Checks for memoized methods whose instance variable name
      # does not match the method name. Applies to both regular methods
      # (defined with `def`) and dynamic methods (defined with
      # `define_method` or `define_singleton_method`).
      #
      # This cop can be configured with the EnforcedStyleForLeadingUnderscores
      # directive. It can be configured to allow for memoized instance variables
      # prefixed with an underscore. Prefixing ivars with an underscore is a
      # convention that is used to implicitly indicate that an ivar should not
      # be set or referenced outside of the memoization method.
      #
      # @safety
      #   This cop relies on the pattern `@instance_var ||= ...`,
      #   but this is sometimes used for other purposes than memoization
      #   so this cop is considered unsafe. Also, its autocorrection is unsafe
      #   because it may conflict with instance variable names already in use.
      #
      # @example EnforcedStyleForLeadingUnderscores: disallowed (default)
      #   # bad
      #   # Method foo is memoized using an instance variable that is
      #   # not `@foo`. This can cause confusion and bugs.
      #   def foo
      #     @something ||= calculate_expensive_thing
      #   end
      #
      #   def foo
      #     return @something if defined?(@something)
      #     @something = calculate_expensive_thing
      #   end
      #
      #   # good
      #   def _foo
      #     @foo ||= calculate_expensive_thing
      #   end
      #
      #   # good
      #   def foo
      #     @foo ||= calculate_expensive_thing
      #   end
      #
      #   # good
      #   def foo
      #     @foo ||= begin
      #       calculate_expensive_thing
      #     end
      #   end
      #
      #   # good
      #   def foo
      #     helper_variable = something_we_need_to_calculate_foo
      #     @foo ||= calculate_expensive_thing(helper_variable)
      #   end
      #
      #   # good
      #   define_method(:foo) do
      #     @foo ||= calculate_expensive_thing
      #   end
      #
      #   # good
      #   define_method(:foo) do
      #     return @foo if defined?(@foo)
      #     @foo = calculate_expensive_thing
      #   end
      #
      # @example EnforcedStyleForLeadingUnderscores: required
      #   # bad
      #   def foo
      #     @something ||= calculate_expensive_thing
      #   end
      #
      #   # bad
      #   def foo
      #     @foo ||= calculate_expensive_thing
      #   end
      #
      #   def foo
      #     return @foo if defined?(@foo)
      #     @foo = calculate_expensive_thing
      #   end
      #
      #   # good
      #   def foo
      #     @_foo ||= calculate_expensive_thing
      #   end
      #
      #   # good
      #   def _foo
      #     @_foo ||= calculate_expensive_thing
      #   end
      #
      #   def foo
      #     return @_foo if defined?(@_foo)
      #     @_foo = calculate_expensive_thing
      #   end
      #
      #   # good
      #   define_method(:foo) do
      #     @_foo ||= calculate_expensive_thing
      #   end
      #
      #   # good
      #   define_method(:foo) do
      #     return @_foo if defined?(@_foo)
      #     @_foo = calculate_expensive_thing
      #   end
      #
      # @example EnforcedStyleForLeadingUnderscores :optional
      #   # bad
      #   def foo
      #     @something ||= calculate_expensive_thing
      #   end
      #
      #   # good
      #   def foo
      #     @foo ||= calculate_expensive_thing
      #   end
      #
      #   # good
      #   def foo
      #     @_foo ||= calculate_expensive_thing
      #   end
      #
      #   # good
      #   def _foo
      #     @_foo ||= calculate_expensive_thing
      #   end
      #
      #   # good
      #   def foo
      #     return @_foo if defined?(@_foo)
      #     @_foo = calculate_expensive_thing
      #   end
      #
      #   # good
      #   define_method(:foo) do
      #     @foo ||= calculate_expensive_thing
      #   end
      #
      #   # good
      #   define_method(:foo) do
      #     @_foo ||= calculate_expensive_thing
      #   end
      class MemoizedInstanceVariableName < Base
        extend AutoCorrector

        include ConfigurableEnforcedStyle

        MSG = 'Memoized variable `%<var>s` does not match ' \
              'method name `%<method>s`. Use `@%<suggested_var>s` instead.'
        UNDERSCORE_REQUIRED = 'Memoized variable `%<var>s` does not start ' \
                              'with `_`. Use `@%<suggested_var>s` instead.'
        DYNAMIC_DEFINE_METHODS = %i[define_method define_singleton_method].to_set.freeze
        INITIALIZE_METHODS = %i[initialize initialize_clone initialize_copy initialize_dup].freeze

        # @!method method_definition?(node)
        def_node_matcher :method_definition?, <<~PATTERN
          ${
            (block (send _ %DYNAMIC_DEFINE_METHODS ({sym str} $_)) ...)
            (def $_ ...)
            (defs _ $_ ...)
          }
        PATTERN

        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        def on_or_asgn(node)
          lhs = node.lhs
          return unless lhs.ivasgn_type?

          method_node, method_name = find_definition(node)
          return unless method_node

          body = method_node.body
          return unless body == node || body.children.last == node

          return if matches?(method_name, lhs)

          suggested_var = suggested_var(method_name)
          msg = format(
            message(lhs.name),
            var: lhs.name,
            suggested_var: suggested_var,
            method: method_name
          )
          add_offense(lhs, message: msg) do |corrector|
            corrector.replace(lhs.loc.name, "@#{suggested_var}")
          end
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        # @!method defined_memoized?(node, ivar)
        def_node_matcher :defined_memoized?, <<~PATTERN
          (begin
            (if (defined $(ivar %1)) (return $(ivar %1)) nil?)
            ...
            $(ivasgn %1 _))
        PATTERN

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def on_defined?(node)
          arg = node.first_argument
          return false unless arg.ivar_type?

          method_node, method_name = find_definition(node)
          return false unless method_node

          defined_memoized?(method_node.body, arg.name) do |defined_ivar, return_ivar, ivar_assign|
            return false if matches?(method_name, ivar_assign)

            suggested_var = suggested_var(method_name)
            msg = format(
              message(arg.name),
              var: arg.name,
              suggested_var: suggested_var,
              method: method_name
            )
            add_offense(defined_ivar, message: msg) do |corrector|
              corrector.replace(defined_ivar, "@#{suggested_var}")
            end
            add_offense(return_ivar, message: msg) do |corrector|
              corrector.replace(return_ivar, "@#{suggested_var}")
            end
            add_offense(ivar_assign.loc.name, message: msg) do |corrector|
              corrector.replace(ivar_assign.loc.name, "@#{suggested_var}")
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        private

        def style_parameter_name
          'EnforcedStyleForLeadingUnderscores'
        end

        def find_definition(node)
          # Methods can be defined in a `def` or `defs`,
          # or dynamically via a `block` node.
          node.each_ancestor(:any_def, :block).each do |ancestor|
            method_node, method_name = method_definition?(ancestor)
            return [method_node, method_name] if method_node
          end

          nil
        end

        def matches?(method_name, ivar_assign)
          return true if ivar_assign.nil? || INITIALIZE_METHODS.include?(method_name)

          method_name = method_name.to_s.delete('!?=')
          variable_name = ivar_assign.name.to_s.sub('@', '')

          variable_name_candidates(method_name).include?(variable_name)
        end

        def message(variable)
          variable_name = variable.to_s.sub('@', '')

          return UNDERSCORE_REQUIRED if style == :required && !variable_name.start_with?('_')

          MSG
        end

        def suggested_var(method_name)
          suggestion = method_name.to_s.delete('!?=')

          style == :required ? "_#{suggestion}" : suggestion
        end

        def variable_name_candidates(method_name)
          no_underscore = method_name.delete_prefix('_')
          with_underscore = "_#{method_name}"
          case style
          when :required
            [with_underscore,
             method_name.start_with?('_') ? method_name : nil].compact
          when :disallowed
            [method_name, no_underscore]
          when :optional
            [method_name, with_underscore, no_underscore]
          else
            raise 'Unreachable'
          end
        end
      end
    end
  end
end
