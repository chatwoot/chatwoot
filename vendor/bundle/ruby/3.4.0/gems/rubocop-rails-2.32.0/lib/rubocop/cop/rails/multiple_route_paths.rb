# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for mapping a route with multiple paths, which is deprecated and will be removed in Rails 8.1.
      #
      # @example
      #
      #   # bad
      #   get '/users', '/other_path', to: 'users#index'
      #
      #   # good
      #   get '/users', to: 'users#index'
      #   get '/other_path', to: 'users#index'
      #
      class MultipleRoutePaths < Base
        include RoutesHelper
        extend AutoCorrector

        MSG = 'Use separate routes instead of combining multiple route paths in a single route.'
        RESTRICT_ON_SEND = HTTP_METHODS

        IGNORED_ARGUMENT_TYPES = %i[array hash].freeze

        def on_send(node)
          return unless within_routes?(node)

          route_paths = node.arguments.reject { |argument| IGNORED_ARGUMENT_TYPES.include?(argument.type) }
          return if route_paths.count < 2

          add_offense(node) do |corrector|
            corrector.replace(node, migrate_to_multiple_routes(node, route_paths))
          end
        end

        private

        def migrate_to_multiple_routes(node, route_paths)
          rest = route_paths.last.source_range.end.join(node.source_range.end).source
          indentation = ' ' * node.source_range.column

          route_paths.map do |route_path|
            "#{node.method_name} #{route_path.source}#{rest}"
          end.join("\n#{indentation}")
        end
      end
    end
  end
end
