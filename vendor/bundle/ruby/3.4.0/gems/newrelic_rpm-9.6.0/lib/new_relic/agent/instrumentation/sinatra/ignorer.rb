# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Sinatra
    module Ignorer
      def self.should_ignore?(app, type)
        return false if !app.settings.respond_to?(:newrelic_ignores)

        app.settings.newrelic_ignores[type].any? do |pattern|
          pattern.match(app.request.path_info)
        end
      end

      def newrelic_ignore(*routes)
        set_newrelic_ignore(:routes, *routes)
      end

      def newrelic_ignore_apdex(*routes)
        set_newrelic_ignore(:apdex, *routes)
      end

      def newrelic_ignore_enduser(*routes)
        set_newrelic_ignore(:enduser, *routes)
      end

      private

      def set_newrelic_ignore(type, *routes)
        # Important to default this in the context of the actual app
        # If it's done at register time, ignores end up shared between apps.
        set(:newrelic_ignores, Hash.new([])) if !respond_to?(:newrelic_ignores)

        # If we call an ignore without a route, it applies to the whole app
        routes = ['*'] if routes.empty?

        settings.newrelic_ignores[type] += routes.map do |r|
          # Ugly sending to private Base#compile, but we want to mimic
          # exactly Sinatra's mapping of route text to regex
          Array(send(:compile, r)).first
        end
      end
    end
  end
end
