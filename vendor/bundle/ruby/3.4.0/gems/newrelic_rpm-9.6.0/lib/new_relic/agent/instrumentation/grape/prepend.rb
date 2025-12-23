# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Grape
    module Prepend
      def call(env)
        begin
          super(env)
        ensure
          Grape::Instrumentation.capture_transaction(env, self)
        end
      end
    end
  end
end
