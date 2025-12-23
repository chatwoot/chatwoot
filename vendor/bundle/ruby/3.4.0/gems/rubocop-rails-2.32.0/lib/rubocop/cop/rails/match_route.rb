# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Identifies places where defining routes with `match`
      # can be replaced with a specific HTTP method.
      #
      # Don't use `match` to define any routes unless there is a need to map multiple request types
      # among [:get, :post, :patch, :put, :delete] to a single action using the `:via` option.
      #
      # @example
      #   # bad
      #   match ':controller/:action/:id'
      #   match 'photos/:id', to: 'photos#show', via: :get
      #
      #   # good
      #   get ':controller/:action/:id'
      #   get 'photos/:id', to: 'photos#show'
      #   match 'photos/:id', to: 'photos#show', via: [:get, :post]
      #   match 'photos/:id', to: 'photos#show', via: :all
      #
      class MatchRoute < Base
        include RoutesHelper
        extend AutoCorrector

        MSG = 'Use `%<http_method>s` instead of `match` to define a route.'
        RESTRICT_ON_SEND = %i[match].freeze

        def_node_matcher :match_method_call?, <<~PATTERN
          (send nil? :match $_ $(hash ...) ?)
        PATTERN

        def on_send(node)
          match_method_call?(node) do |path_node, options_node|
            return unless within_routes?(node)

            options_node = path_node.hash_type? ? path_node : options_node.first

            if options_node.nil?
              register_offense(node, 'get')
            else
              via = extract_via(options_node)
              return unless via.size == 1 && http_method?(via.first)

              register_offense(node, via.first)
            end
          end
        end

        private

        def register_offense(node, http_method)
          add_offense(node, message: format(MSG, http_method: http_method)) do |corrector|
            match_method_call?(node) do |path_node, options_node|
              options_node = options_node.first

              corrector.replace(node, replacement(path_node, options_node))
            end
          end
        end

        def extract_via(node)
          via_pair = via_pair(node)
          return %i[get] unless via_pair

          _, via = *via_pair

          if via.basic_literal?
            [via.value]
          elsif via.array_type?
            via.values.map(&:value)
          else
            []
          end
        end

        def via_pair(node)
          node.pairs.find { |p| p.key.value == :via }
        end

        def http_method?(method)
          HTTP_METHODS.include?(method.to_sym)
        end

        def replacement(path_node, options_node)
          if path_node.hash_type?
            http_method, options = *http_method_and_options(path_node)
            "#{http_method} #{options.map(&:source).join(', ')}"
          elsif options_node.nil?
            "get #{path_node.source}"
          else
            http_method, options = *http_method_and_options(options_node)

            if options.any?
              "#{http_method} #{path_node.source}, #{options.map(&:source).join(', ')}"
            else
              "#{http_method} #{path_node.source}"
            end
          end
        end

        def http_method_and_options(node)
          via_pair = via_pair(node)
          http_method = extract_via(node).first
          rest_pairs = node.pairs - [via_pair]
          [http_method, rest_pairs]
        end
      end
    end
  end
end
