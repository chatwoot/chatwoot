# frozen_string_literal: true

module Datadog
  module AppSec
    module APISecurity
      # This is a helper module to extract the route pattern from the Rack::Request.
      module RouteExtractor
        SINATRA_ROUTE_KEY = 'sinatra.route'
        SINATRA_ROUTE_SEPARATOR = ' '
        GRAPE_ROUTE_KEY = 'grape.routing_args'
        RAILS_ROUTE_KEY = 'action_dispatch.route_uri_pattern'
        RAILS_ROUTES_KEY = 'action_dispatch.routes'
        RAILS_PATH_PARAMS_KEY = 'action_dispatch.request.path_parameters'
        RAILS_FORMAT_SUFFIX = '(.:format)'

        # HACK: We rely on the fact that each contrib will modify `request.env`
        #       and store information sufficient to compute the canonical
        #       route (ex: `/users/:id`).
        #
        #       When contribs like Sinatra or Grape are used, they could be mounted
        #       into the Rails app, hence you can see the use of the `script_name`
        #       that will contain the path prefix of the mounted app.
        #
        #       Rack
        #         does not support named arguments, so we have to use `path`
        #       Sinatra
        #         uses `sinatra.route` with a string like "GET /users/:id"
        #       Grape
        #         uses `grape.routing_args` with a hash with a `:route_info` key
        #         that contains a `Grape::Router::Route` object that contains
        #         `Grape::Router::Pattern` object with an `origin` method
        #       Rails < 7.1 (slow path)
        #         uses `action_dispatch.routes` to store `ActionDispatch::Routing::RouteSet`
        #         which can recognize requests
        #       Rails > 7.1 (fast path)
        #         uses `action_dispatch.route_uri_pattern` with a string like
        #         "/users/:id(.:format)"
        #
        # WARNING: This method works only *after* the request has been routed.
        #
        # WARNING: In Rails > 7.1 when a route was not found,
        #          action_dispatch.route_uri_pattern will not be set.
        #          In Rails < 7.1 it also will not be set even if a route was found,
        #          but in this case  action_dispatch.request.path_parameters won't be empty.
        def self.route_pattern(request)
          if request.env.key?(GRAPE_ROUTE_KEY)
            pattern = request.env[GRAPE_ROUTE_KEY][:route_info]&.pattern&.origin
            "#{request.script_name}#{pattern}"
          elsif request.env.key?(SINATRA_ROUTE_KEY)
            pattern = request.env[SINATRA_ROUTE_KEY].split(SINATRA_ROUTE_SEPARATOR, 2)[1]
            "#{request.script_name}#{pattern}"
          elsif request.env.key?(RAILS_ROUTE_KEY)
            request.env[RAILS_ROUTE_KEY].delete_suffix(RAILS_FORMAT_SUFFIX)
          elsif request.env.key?(RAILS_ROUTES_KEY) && !request.env.fetch(RAILS_PATH_PARAMS_KEY, {}).empty?
            pattern = request.env[RAILS_ROUTES_KEY].router
              .recognize(request) { |route, _| break route.path.spec.to_s }

            # NOTE: If rails is unable to recognize request it returns empty Array
            pattern = nil if pattern&.empty?

            # NOTE: If rails can't recognize the request, we are going to fallback
            #       to generic request path
            (pattern || request.path).delete_suffix(RAILS_FORMAT_SUFFIX)
          else
            request.path
          end
        end
      end
    end
  end
end
