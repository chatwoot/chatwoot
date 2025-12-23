# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  class Control
    module Frameworks
      # A control used when no framework is detected - the default.
      class Ruby < NewRelic::Control
        def env
          @env ||= ENV['NEW_RELIC_ENV'] || ENV['RUBY_ENV'] || ENV['RAILS_ENV'] ||
            ENV['APP_ENV'] || ENV['RACK_ENV'] || 'development'
        end

        def root
          @root ||= ENV['APP_ROOT'] || '.'
        end

        def init_config(options = {})
        end
      end
    end
  end
end
