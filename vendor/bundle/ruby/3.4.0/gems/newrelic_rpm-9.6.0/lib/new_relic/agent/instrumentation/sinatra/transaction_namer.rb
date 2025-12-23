# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module Sinatra
        module TransactionNamer
          extend self

          SINATRA_ROUTE = 'sinatra.route'

          def transaction_name_for_route(env, request)
            if env.key?(SINATRA_ROUTE)
              env[SINATRA_ROUTE]
            else
              name = route_for_sinatra(env)
              name = route_name_for_padrino(request) if name.nil?
              transaction_name(name, request) unless name.nil?
            end
          end

          def initial_transaction_name(request)
            transaction_name(::NewRelic::Agent::UNKNOWN_METRIC, request)
          end

          def transaction_name(route_text, request)
            verb = http_verb(request)

            route_text = route_text.source if route_text.is_a?(Regexp)
            name = route_text.gsub(%r{^[/^\\A]*(.*?)[/\$\?\\z]*$}, '\1')
            name = NewRelic::ROOT if name.empty?
            name = "#{verb} #{name}" unless verb.nil?
            name
          rescue => e
            ::NewRelic::Agent.logger.debug("#{e.class} : #{e.message} - Error encountered trying to identify Sinatra transaction name")
            ::NewRelic::Agent::UNKNOWN_METRIC
          end

          def http_verb(request)
            request.request_method if request.respond_to?(:request_method)
          end

          # For bare Sinatra, our override on process_route captures the last
          # route into the environment for us to use later on
          def route_for_sinatra(env)
            env['newrelic.last_route']
          end

          # For Padrino, the request object has a copy of the matched route
          # on it when we go to evaluating, so we can just retrieve that
          def route_name_for_padrino(request)
            request.route_obj.original_path
          rescue
            nil
          end
        end
      end
    end
  end
end
