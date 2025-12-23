# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Configuration
      MASK_DEFAULTS = {
        :'thread_profiler' => proc { !NewRelic::Agent::Threading::BacktraceService.is_supported? },
        :'thread_profiler.enabled' => proc { !NewRelic::Agent::Threading::BacktraceService.is_supported? }
      }
    end
  end
end
