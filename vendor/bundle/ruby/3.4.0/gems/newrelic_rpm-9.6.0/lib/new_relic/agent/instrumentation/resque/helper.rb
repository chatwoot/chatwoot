# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module Resque
        module Helper
          extend self

          def resque_fork_per_job?
            ENV['FORK_PER_JOB'] != 'false' && NewRelic::LanguageSupport.can_fork?
          end
        end
      end
    end
  end
end
