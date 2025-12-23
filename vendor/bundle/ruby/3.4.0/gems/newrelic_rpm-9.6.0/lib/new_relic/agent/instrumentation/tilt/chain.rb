# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Tilt
    module Chain
      def self.instrument!
        ::Tilt::Template.module_eval do
          include NewRelic::Agent::Instrumentation::Tilt

          def render_with_new_relic(*args, &block)
            render_with_tracing(*args) {
              render_without_newrelic(*args, &block)
            }
          end

          alias render_without_newrelic render
          alias render render_with_new_relic
        end
      end
    end
  end
end
