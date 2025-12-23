# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Use `config.cop_enabled?('Department/CopName')` instead of
      # traversing the config hash.
      #
      # @example
      #   # `for_cop(...)['Enabled']
      #
      #   # bad
      #   config.for_cop('Department/CopName')['Enabled']
      #
      #   # good
      #   config.cop_enabled?('Department/CopName')
      #
      # @example
      #   # when keeping a cop's config in a local and then checking the `Enabled` key
      #
      #   # bad
      #   cop_config = config.for_cop('Department/CopName')
      #   cop_config['Enabled'] && cop_config['Foo']
      #
      #   # good
      #   config.for_enabled_cop('Department/CopName')['Foo']
      #
      class CopEnabled < Base
        extend AutoCorrector

        MSG = 'Use `%<replacement>s` instead of `%<source>s`.'
        MSG_HASH = 'Consider replacing uses of `%<hash_name>s` with `config.for_enabled_cop`.'

        RESTRICT_ON_SEND = [:[]].freeze

        # @!method for_cop_enabled?(node)
        def_node_matcher :for_cop_enabled?, <<~PATTERN
          (send
            (send
              ${(send nil? :config) (ivar :@config)} :for_cop
              $(str _)) :[]
            (str "Enabled"))
        PATTERN

        # @!method config_enabled_lookup?(node)
        def_node_matcher :config_enabled_lookup?, <<~PATTERN
          (send
            {(lvar $_) (ivar $_) (send nil? $_)} :[]
            (str "Enabled"))
        PATTERN

        def on_send(node)
          if (config_var, cop_name = for_cop_enabled?(node))
            handle_for_cop(node, config_var, cop_name)
          elsif (config_var = config_enabled_lookup?(node))
            return unless config_var.end_with?('_config')

            handle_hash(node, config_var)
          end
        end

        private

        def handle_for_cop(node, config_var, cop_name)
          source = node.source
          quote = cop_name.loc.begin.source
          cop_name = cop_name.value

          replacement = "#{config_var.source}.cop_enabled?(#{quote}#{cop_name}#{quote})"
          message = format(MSG, source: source, replacement: replacement)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        def handle_hash(node, config_var)
          message = format(MSG_HASH, hash_name: config_var)

          add_offense(node, message: message)
        end
      end
    end
  end
end
