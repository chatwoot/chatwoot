# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Memcache
    module Chain
      extend Helper

      def self.instrument!(target_class)
        instrument_methods(target_class, client_methods)
      end
    end
  end
end
