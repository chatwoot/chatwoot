# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for places where redundant assignments are made for in place
      # modification methods.
      #
      # @safety
      #   This cop is unsafe, because it can produce false positives for
      #   user defined methods having one of the expected names, but not modifying
      #   its receiver in place.
      #
      # @example
      #   # bad
      #   args = args.concat(ary)
      #   hash = hash.merge!(other)
      #
      #   # good
      #   args.concat(foo)
      #   args += foo
      #   hash.merge!(other)
      #
      #   # good
      #   foo.concat(ary)
      #
      class RedundantSelfAssignment < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Redundant self assignment detected. ' \
              'Method `%<method_name>s` modifies its receiver in place.'

        METHODS_RETURNING_SELF = %i[
          append clear collect! compare_by_identity concat delete_if
          fill initialize_copy insert keep_if map! merge! prepend push
          rehash replace reverse! rotate! shuffle! sort! sort_by!
          transform_keys! transform_values! unshift update
        ].to_set.freeze

        ASSIGNMENT_TYPE_TO_RECEIVER_TYPE = {
          lvasgn: :lvar,
          ivasgn: :ivar,
          cvasgn: :cvar,
          gvasgn: :gvar
        }.freeze

        # @!method redundant_self_assignment?
        def_node_matcher :redundant_self_assignment?, <<~PATTERN
          (call
            %1 _
            (call
              (call
                %1 %2) #method_returning_self?
              ...))
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_lvasgn(node)
          return unless (rhs = node.rhs)
          return unless rhs.type?(:any_block, :call) && method_returning_self?(rhs.method_name)
          return unless (receiver = rhs.receiver)

          receiver_type = ASSIGNMENT_TYPE_TO_RECEIVER_TYPE[node.type]
          return unless receiver.type == receiver_type && receiver.children.first == node.lhs

          message = format(MSG, method_name: rhs.method_name)
          add_offense(node.loc.operator, message: message) do |corrector|
            corrector.replace(node, rhs.source)
          end
        end
        # rubocop:enable Metrics/AbcSize
        alias on_ivasgn on_lvasgn
        alias on_cvasgn on_lvasgn
        alias on_gvasgn on_lvasgn

        def on_send(node)
          return unless node.assignment_method?
          return unless redundant_assignment?(node)

          message = format(MSG, method_name: node.first_argument.method_name)
          add_offense(node.loc.operator, message: message) do |corrector|
            corrector.remove(correction_range(node))
          end
        end
        alias on_csend on_send

        private

        def method_returning_self?(method_name)
          METHODS_RETURNING_SELF.include?(method_name)
        end

        def redundant_assignment?(node)
          receiver_name = node.method_name.to_s.delete_suffix('=').to_sym

          redundant_self_assignment?(node, node.receiver, receiver_name)
        end

        def correction_range(node)
          range_between(node.source_range.begin_pos, node.first_argument.source_range.begin_pos)
        end
      end
    end
  end
end
