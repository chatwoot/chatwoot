# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for options hashes and discourages them if the
      # current Ruby version supports keyword arguments.
      #
      # @example
      #
      #   # bad
      #   def fry(options = {})
      #     temperature = options.fetch(:temperature, 300)
      #     # ...
      #   end
      #
      #
      #   # good
      #   def fry(temperature: 300)
      #     # ...
      #   end
      class OptionHash < Base
        MSG = 'Prefer keyword arguments to options hashes.'

        # @!method option_hash(node)
        def_node_matcher :option_hash, <<~PATTERN
          (args ... $(optarg [#suspicious_name? _] (hash)))
        PATTERN

        def on_args(node)
          return if super_used?(node)
          return if allowlist.include?(node.parent.method_name.to_s)

          option_hash(node) { |options| add_offense(options) }
        end

        private

        def allowlist
          cop_config['Allowlist'] || []
        end

        def suspicious_name?(arg_name)
          cop_config.key?('SuspiciousParamNames') &&
            cop_config['SuspiciousParamNames'].include?(arg_name.to_s)
        end

        def super_used?(node)
          node.parent.each_node(:zsuper).any?
        end
      end
    end
  end
end
