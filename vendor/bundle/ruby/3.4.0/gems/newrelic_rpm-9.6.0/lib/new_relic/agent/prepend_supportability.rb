# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module PrependSupportability
      def self.record_metrics_for(*classes)
        classes.each do |klass|
          count = klass.send(:ancestors).index(klass)
          ::NewRelic::Agent.record_metric("Supportability/PrependedModules/#{klass}", count) if count > 0
        end
      end
    end
  end
end
