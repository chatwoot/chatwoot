# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'
require_relative 'events'

module Datadog
  module Tracing
    module Contrib
      module ActiveModelSerializers
        # Patcher enables patching of 'active_model_serializers' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            Events.subscribe!
          end

          def get_option(option)
            Datadog.configuration.tracing[:active_model_serializers].get_option(option)
          end
        end
      end
    end
  end
end
