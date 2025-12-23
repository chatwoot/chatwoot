# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of consistent method names
      # `Object#yield_self` or `Object#then`.
      #
      # @example EnforcedStyle: then (default)
      #
      #   # bad
      #   obj.yield_self { |x| x.do_something }
      #
      #   # good
      #   obj.then { |x| x.do_something }
      #
      # @example EnforcedStyle: yield_self
      #
      #   # bad
      #   obj.then { |x| x.do_something }
      #
      #   # good
      #   obj.yield_self { |x| x.do_something }
      #
      class ObjectThen < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.6

        MSG = 'Prefer `%<prefer>s` over `%<current>s`.'
        RESTRICT_ON_SEND = %i[then yield_self].freeze

        def on_block(node)
          return unless RESTRICT_ON_SEND.include?(node.method_name)

          check_method_node(node.send_node)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        def on_send(node)
          return unless node.arguments.one? && node.first_argument.block_pass_type?

          check_method_node(node)
        end
        alias on_csend on_send

        private

        def check_method_node(node)
          if preferred_method?(node)
            correct_style_detected
          else
            opposite_style_detected
            message = message(node)
            add_offense(node.loc.selector, message: message) do |corrector|
              prefer = style == :then && node.receiver.nil? ? 'self.then' : style

              corrector.replace(node.loc.selector, prefer)
            end
          end
        end

        def preferred_method?(node)
          node.method?(style)
        end

        def message(node)
          format(MSG, prefer: style.to_s, current: node.method_name)
        end
      end
    end
  end
end
