# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/control/frameworks/rails4'

module NewRelic
  class Control
    module Frameworks
      class RailsNotifications < NewRelic::Control::Frameworks::Rails4
      end
    end
  end
end
