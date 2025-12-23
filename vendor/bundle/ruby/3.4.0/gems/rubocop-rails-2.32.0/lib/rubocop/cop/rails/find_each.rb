# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies usages of `all.each` and change them to use `all.find_each` instead.
      #
      # @safety
      #   This cop is unsafe if the receiver object is not an Active Record object.
      #   Also, `all.each` returns an `Array` instance and `all.find_each` returns nil,
      #   so the return values are different.
      #
      # @example
      #   # bad
      #   User.all.each
      #
      #   # good
      #   User.all.find_each
      #
      # @example AllowedMethods: ['order']
      #   # good
      #   User.order(:foo).each
      #
      # @example AllowedPattern: ['order']
      #   # good
      #   User.order(:foo).each
      class FindEach < Base
        include ActiveRecordHelper
        include AllowedMethods
        include AllowedPattern
        extend AutoCorrector

        MSG = 'Use `find_each` instead of `each`.'
        RESTRICT_ON_SEND = %i[each].freeze

        SCOPE_METHODS = %i[
          all eager_load includes joins left_joins left_outer_joins not or preload
          references unscoped where
        ].freeze

        def on_send(node)
          return unless node.receiver&.send_type?
          return unless SCOPE_METHODS.include?(node.receiver.method_name)
          return if node.receiver.receiver.nil? && !inherit_active_record_base?(node)
          return if ignored?(node)

          range = node.loc.selector
          add_offense(range) do |corrector|
            corrector.replace(range, 'find_each')
          end
        end

        private

        def ignored?(node)
          return true if active_model_error_where?(node.receiver)

          method_chain = node.each_node(:send).map(&:method_name)

          method_chain.any? { |method_name| allowed_method?(method_name) || matches_allowed_pattern?(method_name) }
        end

        def active_model_error_where?(node)
          node.method?(:where) && active_model_error?(node.receiver)
        end

        def active_model_error?(node)
          return false if node.nil?

          node.send_type? && node.method?(:errors)
        end
      end
    end
  end
end
