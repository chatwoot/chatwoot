# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks potentially usage of method identifier predicates
      # defined in rubocop-ast instead of `method_name.end_with?`.
      #
      # @example
      #   # bad
      #   node.method_name.to_s.end_with?('=')
      #
      #   # good
      #   node.assignment_method?
      #
      #   # bad
      #   node.method_name.to_s.end_with?('?')
      #
      #   # good
      #   node.predicate_method?
      #
      #   # bad
      #   node.method_name.to_s.end_with?('!')
      #
      #   # good
      #   node.bang_method?
      #
      class MethodNameEndWith < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<method_name>s` instead of `%<method_suffix>s`.'
        RESTRICT_ON_SEND = %i[end_with?].freeze
        SUGGEST_METHOD_FOR_SUFFIX = {
          '=' => 'assignment_method?',
          '!' => 'bang_method?',
          '?' => 'predicate_method?'
        }.freeze

        # @!method method_name_end_with?(node)
        def_node_matcher :method_name_end_with?, <<~PATTERN
          {
            (call
              (call
                $(... :method_name) :to_s) :end_with?
              $(str {"=" "?" "!"}))
            (call
              $(... :method_name) :end_with?
            $(str {"=" "?" "!"}))
          }
        PATTERN

        def on_send(node)
          method_name_end_with?(node) do |method_name_node, end_with_arg|
            next unless method_name_node.receiver

            preferred_method = SUGGEST_METHOD_FOR_SUFFIX[end_with_arg.value]
            range = range(method_name_node, node)
            message = format(MSG, method_name: preferred_method, method_suffix: range.source)

            add_offense(range, message: message) do |corrector|
              corrector.replace(range, preferred_method)
            end
          end
        end
        alias on_csend on_send

        private

        def range(method_name_node, node)
          range = if method_name_node.call_type?
                    method_name_node.loc.selector
                  else
                    method_name_node.source_range
                  end

          range_between(range.begin_pos, node.source_range.end_pos)
        end
      end
    end
  end
end
