# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/event_listener'
require 'new_relic/rack/agent_middleware'
require 'new_relic/agent/instrumentation/middleware_proxy'

module NewRelic::Rack
  # This middleware is used internally by the agent in the rare case
  # where the disable_middleware_instrumentation configuration setting
  # is true.  In Rails and Sinatra applications this middleware will be
  # automatically injected if necessary.
  #
  # If you have disabled middleware instrumentation and are not using Rails or
  # Sinatra you can include this middleware manually in your config.ru file.
  #
  # All of the functionality of this module resides in the MiddlewareTracing
  # module, which is shared between it and our third party middleware
  # instrumentation.
  #
  # @api public
  #
  class AgentHooks < AgentMiddleware
    def self.needed?
      NewRelic::Agent.config[:disable_middleware_instrumentation]
    end

    def traced_call(env)
      @app.call(env)
    end
  end
end
