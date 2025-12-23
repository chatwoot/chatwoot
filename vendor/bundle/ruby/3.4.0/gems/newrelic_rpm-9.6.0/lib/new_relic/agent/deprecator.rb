# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Deprecator
      def self.deprecate(method_name, new_method_name = nil, version = nil)
        msgs = ["The method #{method_name} is deprecated."]
        msgs << "It will be removed in version #{version}." if version
        msgs << "Please use #{new_method_name} instead." if new_method_name

        NewRelic::Agent.logger.log_once(:warn, "deprecated_#{method_name}".to_sym, msgs)
        NewRelic::Agent.record_metric("Supportability/Deprecated/#{method_name}", 1)
      end
    end
  end
end
