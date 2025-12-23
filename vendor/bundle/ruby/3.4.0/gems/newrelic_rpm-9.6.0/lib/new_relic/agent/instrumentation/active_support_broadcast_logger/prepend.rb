# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module ActiveSupportBroadcastLogger::Prepend
    include NewRelic::Agent::Instrumentation::ActiveSupportBroadcastLogger

    def add(*args)
      record_one_broadcast_with_new_relic(*args) { super }
    end

    def debug(*args)
      record_one_broadcast_with_new_relic(*args) { super }
    end

    def info(*args)
      record_one_broadcast_with_new_relic(*args) { super }
    end

    def warn(*args)
      record_one_broadcast_with_new_relic(*args) { super }
    end

    def error(*args)
      record_one_broadcast_with_new_relic(*args) { super }
    end

    def fatal(*args)
      record_one_broadcast_with_new_relic(*args) { super }
    end

    def unknown(*args)
      record_one_broadcast_with_new_relic(*args) { super }
    end
  end
end
