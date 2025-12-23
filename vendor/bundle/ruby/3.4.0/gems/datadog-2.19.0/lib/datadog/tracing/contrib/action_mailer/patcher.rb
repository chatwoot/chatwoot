# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'
require_relative 'events'

module Datadog
  module Tracing
    module Contrib
      module ActionMailer
        # Patcher enables patching of 'action_mailer' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            # Subscribe to ActionMailer events
            Events.subscribe!
          end
        end
      end
    end
  end
end
