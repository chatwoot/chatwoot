# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks legacy syntax usage of `tag`
      #
      # NOTE: Allow `tag` when the first argument is a variable because
      # `tag(name)` is simpler rather than `tag.public_send(name)`.
      # And this cop will be renamed to something like `LegacyTag` in the future. (e.g. RuboCop Rails 3.0)
      #
      # @example
      #  # bad
      #  tag(:p)
      #  tag(:br, class: 'classname')
      #
      #  # good
      #  tag.p
      #  tag.br(class: 'classname')
      #  tag(name, class: 'classname')
      class ContentTag < Base
        include RangeHelp
        extend AutoCorrector
        extend TargetRailsVersion

        minimum_target_rails_version 5.1

        MSG = 'Use `tag.%<preferred_method>s` instead of `tag(%<current_argument>s)`.'
        RESTRICT_ON_SEND = %i[tag].freeze

        def on_new_investigation
          @corrected_nodes = nil
        end

        def on_send(node)
          return unless node.receiver.nil?
          return if node.arguments.count >= 3

          first_argument = node.first_argument
          return if !first_argument || allowed_argument?(first_argument) || corrected_ancestor?(node)

          preferred_method = node.first_argument.value.to_s.underscore
          message = format(MSG, preferred_method: preferred_method, current_argument: first_argument.source)

          register_offense(node, message, preferred_method)
        end

        private

        def corrected_ancestor?(node)
          node.each_ancestor(:send).any? { |ancestor| @corrected_nodes&.include?(ancestor) }
        end

        def allowed_argument?(argument)
          argument.variable? ||
            argument.send_type? ||
            argument.const_type? ||
            argument.splat_type? ||
            allowed_name?(argument) ||
            !argument.respond_to?(:value)
        end

        def register_offense(node, message, preferred_method)
          add_offense(node, message: message) do |corrector|
            autocorrect(corrector, node, preferred_method)

            @corrected_nodes ||= Set.new.compare_by_identity
            @corrected_nodes.add(node)
          end
        end

        def autocorrect(corrector, node, preferred_method)
          range = correction_range(node)

          rest_args = node.arguments.drop(1)
          replacement = "tag.#{preferred_method}(#{rest_args.map(&:source).join(', ')})"

          corrector.replace(range, replacement)
        end

        def allowed_name?(argument)
          return false unless argument.type?(:str, :sym)

          !/^[a-zA-Z-][a-zA-Z\-0-9]*$/.match?(argument.value)
        end

        def correction_range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end
      end
    end
  end
end
