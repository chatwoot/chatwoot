# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies usages of `first`, `last`, `[0]` or `[-1]`
      # chained to `select`, `find_all` or `filter` and change them to use
      # `detect` instead.
      #
      # @safety
      #   This cop is unsafe because it assumes that the receiver is an
      #   `Array` or equivalent, but can't reliably detect it. For example,
      #   if the receiver is a `Hash`, it may report a false positive.
      #
      # @example
      #   # bad
      #   [].select { |item| true }.first
      #   [].select { |item| true }.last
      #   [].find_all { |item| true }.first
      #   [].find_all { |item| true }.last
      #   [].filter { |item| true }.first
      #   [].filter { |item| true }.last
      #   [].filter { |item| true }[0]
      #   [].filter { |item| true }[-1]
      #
      #   # good
      #   [].detect { |item| true }
      #   [].reverse.detect { |item| true }
      #
      class Detect < Base
        extend AutoCorrector

        CANDIDATE_METHODS = Set[:select, :find_all, :filter].freeze

        MSG = 'Use `%<prefer>s` instead of `%<first_method>s.%<second_method>s`.'
        REVERSE_MSG = 'Use `reverse.%<prefer>s` instead of `%<first_method>s.%<second_method>s`.'
        INDEX_MSG = 'Use `%<prefer>s` instead of `%<first_method>s[%<index>i]`.'
        INDEX_REVERSE_MSG = 'Use `reverse.%<prefer>s` instead of `%<first_method>s[%<index>i]`.'
        RESTRICT_ON_SEND = %i[first last []].freeze

        def_node_matcher :detect_candidate?, <<~PATTERN
          {
            (send $(block (call _ %CANDIDATE_METHODS) ...) ${:first :last} $...)
            (send $(block (send _ %CANDIDATE_METHODS) ...) $:[] (int ${0 -1}))
            (send $(call _ %CANDIDATE_METHODS ...) ${:first :last} $...)
            (send $(send _ %CANDIDATE_METHODS ...) $:[] (int ${0 -1}))
          }
        PATTERN

        def on_send(node)
          detect_candidate?(node) do |receiver, second_method, args|
            if second_method == :[]
              index = args
              args = {}
            end

            return unless args.empty?
            return unless receiver

            receiver, _args, body = *receiver if receiver.block_type?
            return if accept_first_call?(receiver, body)

            register_offense(node, receiver, second_method, index)
          end
        end
        alias on_csend on_send

        private

        def accept_first_call?(receiver, body)
          caller, _first_method, args = *receiver

          # check that we have usual block or block pass
          return true if body.nil? && (args.nil? || !args.block_pass_type?)

          lazy?(caller)
        end

        def register_offense(node, receiver, second_method, index)
          _caller, first_method, _args = *receiver
          range = receiver.loc.selector.join(node.loc.selector)

          message = message_for_method(second_method, index)
          formatted_message = format(message, prefer: preferred_method,
                                              first_method: first_method,
                                              second_method: second_method,
                                              index: index)

          add_offense(range, message: formatted_message) do |corrector|
            autocorrect(corrector, node, replacement(second_method, index))
          end
        end

        def replacement(method, index)
          if method == :last || (method == :[] && index == -1)
            "reverse.#{preferred_method}"
          else
            preferred_method
          end
        end

        def autocorrect(corrector, node, replacement)
          receiver, _first_method = *node

          first_range = receiver.source_range.end.join(node.loc.selector)

          receiver, _args, _body = *receiver if receiver.block_type?

          corrector.remove(first_range)
          corrector.replace(receiver.loc.selector, replacement)
        end

        def message_for_method(method, index)
          case method
          when :[]
            index == -1 ? INDEX_REVERSE_MSG : INDEX_MSG
          when :last
            REVERSE_MSG
          else
            MSG
          end
        end

        def preferred_method
          config.for_cop('Style/CollectionMethods')['PreferredMethods']['detect'] || 'detect'
        end

        def lazy?(node)
          return false unless node

          receiver, method, _args = *node
          method == :lazy && !receiver.nil?
        end
      end
    end
  end
end
