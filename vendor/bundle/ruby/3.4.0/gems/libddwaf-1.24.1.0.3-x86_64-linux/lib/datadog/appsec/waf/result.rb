# frozen_string_literal: true

module Datadog
  module AppSec
    module WAF
      # Ruby representation of the ddwaf_result of a libddwaf run.
      # See https://github.com/DataDog/libddwaf/blob/10e3a1dfc7bc9bb8ab11a09a9f8b6b339eaf3271/include/ddwaf.h#L159-L173
      class Result
        attr_reader :status, :events, :total_runtime, :timeout, :actions, :derivatives

        def initialize(status, events, total_runtime, timeout, actions, derivatives)
          @status = status
          @events = events
          @total_runtime = total_runtime
          @timeout = timeout
          @actions = actions
          @derivatives = derivatives
        end

        def to_h
          {
            status: @status,
            events: @events,
            total_runtime: @total_runtime,
            timeout: @timeout,
            actions: @actions,
            derivatives: @derivatives
          }
        end
      end
    end
  end
end
