# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # In Ruby 3.1, `Array#intersect?` has been added.
      #
      # This cop identifies places where `(array1 & array2).any?`
      # or `(array1.intersection(array2)).any?` can be replaced by
      # `array1.intersect?(array2)`.
      #
      # The `array1.intersect?(array2)` method is faster than
      # `(array1 & array2).any?` and is more readable.
      #
      # In cases like the following, compatibility is not ensured,
      # so it will not be detected when using block argument.
      #
      # [source,ruby]
      # ----
      # ([1] & [1,2]).any? { |x| false }    # => false
      # [1].intersect?([1,2]) { |x| false } # => true
      # ----
      #
      # NOTE: Although `Array#intersection` can take zero or multiple arguments,
      # only cases where exactly one argument is provided can be replaced with
      # `Array#intersect?` and are handled by this cop.
      #
      # @safety
      #   This cop cannot guarantee that `array1` and `array2` are
      #   actually arrays while method `intersect?` is for arrays only.
      #
      # @example
      #   # bad
      #   (array1 & array2).any?
      #   (array1 & array2).empty?
      #   (array1 & array2).none?
      #
      #   # bad
      #   array1.intersection(array2).any?
      #   array1.intersection(array2).empty?
      #   array1.intersection(array2).none?
      #
      #   # good
      #   array1.intersect?(array2)
      #   !array1.intersect?(array2)
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: false (default)
      #   # good
      #   (array1 & array2).present?
      #   (array1 & array2).blank?
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: true
      #   # bad
      #   (array1 & array2).present?
      #   (array1 & array2).blank?
      #
      #   # good
      #   array1.intersect?(array2)
      #   !array1.intersect?(array2)
      class ArrayIntersect < Base
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 3.1

        PREDICATES = %i[any? empty? none?].to_set.freeze
        ACTIVE_SUPPORT_PREDICATES = (PREDICATES + %i[present? blank?]).freeze

        # @!method bad_intersection_check?(node, predicates)
        def_node_matcher :bad_intersection_check?, <<~PATTERN
          (call
            {
              (begin (send $_ :& $_))
              (call $_ :intersection $_)
            }
            $%1
          )
        PATTERN

        MSG = 'Use `%<negated>s%<receiver>s%<dot>sintersect?(%<argument>s)` ' \
              'instead of `%<existing>s`.'
        STRAIGHT_METHODS = %i[present? any?].freeze
        NEGATED_METHODS = %i[blank? empty? none?].freeze
        RESTRICT_ON_SEND = (STRAIGHT_METHODS + NEGATED_METHODS).freeze

        def on_send(node)
          return if node.block_literal?
          return unless (receiver, argument, method_name = bad_intersection?(node))

          dot = node.loc.dot.source
          message = message(receiver.source, argument.source, method_name, dot, node.source)

          add_offense(node, message: message) do |corrector|
            bang = straight?(method_name) ? '' : '!'

            corrector.replace(node, "#{bang}#{receiver.source}#{dot}intersect?(#{argument.source})")
          end
        end
        alias on_csend on_send

        private

        def bad_intersection?(node)
          predicates = if active_support_extensions_enabled?
                         ACTIVE_SUPPORT_PREDICATES
                       else
                         PREDICATES
                       end

          bad_intersection_check?(node, predicates)
        end

        def straight?(method_name)
          STRAIGHT_METHODS.include?(method_name.to_sym)
        end

        def message(receiver, argument, method_name, dot, existing)
          negated = straight?(method_name) ? '' : '!'
          format(
            MSG,
            negated: negated,
            receiver: receiver,
            argument: argument,
            dot: dot,
            existing: existing
          )
        end
      end
    end
  end
end
