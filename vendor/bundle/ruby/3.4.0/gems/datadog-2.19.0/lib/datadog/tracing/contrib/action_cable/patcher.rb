# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'
require_relative 'events'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      module ActionCable
        # Patcher enables patching of 'action_cable' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            Events.subscribe!
            ::ActionCable::Connection::Base.prepend(Instrumentation::ActionCableConnection)
            ::ActionCable::Channel::Base.include(Instrumentation::ActionCableChannel)
          end
        end
      end
    end
  end
end
