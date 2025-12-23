# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Checks for methods with too many parameters.
      #
      # The maximum number of parameters is configurable.
      # Keyword arguments can optionally be excluded from the total count,
      # as they add less complexity than positional or optional parameters.
      #
      # Any number of arguments for `initialize` method inside a block of
      # `Struct.new` and `Data.define` like this is always allowed:
      #
      # [source,ruby]
      # ----
      # Struct.new(:one, :two, :three, :four, :five, keyword_init: true) do
      #   def initialize(one:, two:, three:, four:, five:)
      #   end
      # end
      # ----
      #
      # This is because checking the number of arguments of the `initialize` method
      # does not make sense.
      #
      # NOTE: Explicit block argument `&block` is not counted to prevent
      # erroneous change that is avoided by making block argument implicit.
      #
      # @example Max: 3
      #   # good
      #   def foo(a, b, c = 1)
      #   end
      #
      # @example Max: 2
      #   # bad
      #   def foo(a, b, c = 1)
      #   end
      #
      # @example CountKeywordArgs: true (default)
      #   # counts keyword args towards the maximum
      #
      #   # bad (assuming Max is 3)
      #   def foo(a, b, c, d: 1)
      #   end
      #
      #   # good (assuming Max is 3)
      #   def foo(a, b, c: 1)
      #   end
      #
      # @example CountKeywordArgs: false
      #   # don't count keyword args towards the maximum
      #
      #   # good (assuming Max is 3)
      #   def foo(a, b, c, d: 1)
      #   end
      #
      # This cop also checks for the maximum number of optional parameters.
      # This can be configured using the `MaxOptionalParameters` config option.
      #
      # @example MaxOptionalParameters: 3 (default)
      #   # good
      #   def foo(a = 1, b = 2, c = 3)
      #   end
      #
      # @example MaxOptionalParameters: 2
      #   # bad
      #   def foo(a = 1, b = 2, c = 3)
      #   end
      #
      class ParameterLists < Base
        exclude_limit 'Max'
        exclude_limit 'MaxOptionalParameters'

        MSG = 'Avoid parameter lists longer than %<max>d parameters. [%<count>d/%<max>d]'
        OPTIONAL_PARAMETERS_MSG = 'Method has too many optional parameters. [%<count>d/%<max>d]'

        NAMED_KEYWORD_TYPES = %i[kwoptarg kwarg].freeze
        private_constant :NAMED_KEYWORD_TYPES

        # @!method struct_new_or_data_define_block?(node)
        def_node_matcher :struct_new_or_data_define_block?, <<~PATTERN
          (block
            {
              (send (const {nil? cbase} :Struct) :new ...)
              (send (const {nil? cbase} :Data) :define ...)
            }
            (args) ...)
        PATTERN

        def on_def(node)
          optargs = node.arguments.select(&:optarg_type?)
          return if optargs.count <= max_optional_parameters

          message = format(
            OPTIONAL_PARAMETERS_MSG,
            max: max_optional_parameters,
            count: optargs.count
          )

          add_offense(node, message: message) { self.max_optional_parameters = optargs.count }
        end
        alias on_defs on_def

        def on_args(node)
          parent = node.parent
          return if parent.method?(:initialize) && struct_new_or_data_define_block?(parent.parent)

          count = args_count(node)
          return unless count > max_params

          return if argument_to_lambda_or_proc?(node)

          add_offense(node, message: format(MSG, max: max_params, count: args_count(node))) do
            self.max = count
          end
        end

        private

        # @!method argument_to_lambda_or_proc?(node)
        def_node_matcher :argument_to_lambda_or_proc?, <<~PATTERN
          ^lambda_or_proc?
        PATTERN

        def args_count(node)
          if count_keyword_args?
            node.children.count { |a| !a.blockarg_type? }
          else
            node.children.count { |a| !NAMED_KEYWORD_TYPES.include?(a.type) && !a.blockarg_type? }
          end
        end

        def max_params
          cop_config['Max']
        end

        def max_optional_parameters
          cop_config['MaxOptionalParameters']
        end

        def count_keyword_args?
          cop_config['CountKeywordArgs']
        end
      end
    end
  end
end
