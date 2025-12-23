# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  class Control
    # Contains subclasses of NewRelic::Control that are used when
    # starting the agent within an application. Framework-specific
    # logic should be included here, as documented within the Control
    # abstract parent class
    module Frameworks
    end
  end
end
