# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Tilt::Prepend
    include NewRelic::Agent::Instrumentation::Tilt

    def render(*args, &block)
      render_with_tracing { super }
    end
  end
end
