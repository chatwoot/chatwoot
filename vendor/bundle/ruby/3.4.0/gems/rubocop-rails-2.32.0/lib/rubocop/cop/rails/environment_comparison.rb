# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that Rails.env is compared using `.production?`-like
      # methods instead of equality against a string or symbol.
      #
      # @example
      #   # bad
      #   Rails.env == 'production'
      #
      #   # bad, always returns false
      #   Rails.env == :test
      #
      #   # good
      #   Rails.env.production?
      class EnvironmentComparison < Base
        extend AutoCorrector

        MSG = 'Favor `%<bang>sRails.env.%<env>s?` over `%<source>s`.'

        SYM_MSG = 'Do not compare `Rails.env` with a symbol, it will always evaluate to `false`.'

        RESTRICT_ON_SEND = %i[== !=].freeze

        def_node_matcher :comparing_str_env_with_rails_env_on_lhs?, <<~PATTERN
          (send
            (send (const {nil? cbase} :Rails) :env)
            {:== :!=}
            $str
          )
        PATTERN

        def_node_matcher :comparing_str_env_with_rails_env_on_rhs?, <<~PATTERN
          (send
            $str
            {:== :!=}
            (send (const {nil? cbase} :Rails) :env)
          )
        PATTERN

        def_node_matcher :comparing_sym_env_with_rails_env_on_lhs?, <<~PATTERN
          (send
            (send (const {nil? cbase} :Rails) :env)
            {:== :!=}
            $sym
          )
        PATTERN

        def_node_matcher :comparing_sym_env_with_rails_env_on_rhs?, <<~PATTERN
          (send
            $sym
            {:== :!=}
            (send (const {nil? cbase} :Rails) :env)
          )
        PATTERN

        def_node_matcher :content, <<~PATTERN
          ({str sym} $_)
        PATTERN

        def on_send(node)
          if (env_node = comparing_str_env_with_rails_env_on_lhs?(node) ||
                         comparing_str_env_with_rails_env_on_rhs?(node))
            env, = *env_node
            bang = node.method?(:!=) ? '!' : ''
            message = format(MSG, bang: bang, env: env, source: node.source)

            add_offense(node, message: message) do |corrector|
              autocorrect(corrector, node)
            end
          end

          return unless comparing_sym_env_with_rails_env_on_lhs?(node) || comparing_sym_env_with_rails_env_on_rhs?(node)

          add_offense(node, message: SYM_MSG) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def autocorrect(corrector, node)
          replacement = build_predicate_method(node)

          corrector.replace(node, replacement)
        end

        def build_predicate_method(node)
          if rails_env_on_lhs?(node)
            build_predicate_method_for_rails_env_on_lhs(node)
          else
            build_predicate_method_for_rails_env_on_rhs(node)
          end
        end

        def rails_env_on_lhs?(node)
          comparing_str_env_with_rails_env_on_lhs?(node) || comparing_sym_env_with_rails_env_on_lhs?(node)
        end

        def build_predicate_method_for_rails_env_on_lhs(node)
          bang = node.method?(:!=) ? '!' : ''

          "#{bang}#{node.receiver.source}.#{content(node.first_argument)}?"
        end

        def build_predicate_method_for_rails_env_on_rhs(node)
          bang = node.method?(:!=) ? '!' : ''

          "#{bang}#{node.first_argument.source}.#{content(node.receiver)}?"
        end
      end
    end
  end
end
