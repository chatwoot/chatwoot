# frozen_string_literal: true

require 'time'

require_relative '../../metadata/ext'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module Sinatra
        # Gets and sets trace information from a Rack Env
        module Env
          module_function

          def datadog_span(env)
            env[Ext::RACK_ENV_SINATRA_REQUEST_SPAN]
          end

          def set_datadog_span(env, span)
            env[Ext::RACK_ENV_SINATRA_REQUEST_SPAN] = span
          end

          def route_path(env, use_script_names: Datadog.configuration.tracing[:sinatra][:resource_script_names])
            return unless env['sinatra.route']

            _, path = env['sinatra.route'].split(' ', 2)
            if use_script_names
              env['SCRIPT_NAME'].to_s + path
            else
              path
            end
          end
        end
      end
    end
  end
end
