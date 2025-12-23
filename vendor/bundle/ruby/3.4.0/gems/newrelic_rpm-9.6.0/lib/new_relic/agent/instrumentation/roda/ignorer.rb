# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Roda
    module Ignorer
      def self.should_ignore?(app, type)
        return false unless app.opts.include?(:newrelic_ignores)

        app.opts[:newrelic_ignores][type].any? do |pattern|
          pattern === app.request.path_info
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
        # Create a newrelic_ignores hash if one doesn't exist
        opts[:newrelic_ignores] = Hash.new([]) if !opts.include?(:newrelic_ignores)

        if routes.empty?
          opts[:newrelic_ignores][type] += [Regexp.new('.*')]
        else
          opts[:newrelic_ignores][type] += routes.map do |r|
            # Roda adds leading slashes to routes, so we need to do the same
            "#{'/' unless r.start_with?('/')}#{r}"
          end
        end
      end
    end
  end
end
