# frozen_string_literal: true

require_relative '../active_support/notifications/event'

module Datadog
  module Tracing
    module Contrib
      module ActiveRecord
        # Defines basic behaviors for an ActiveRecord event.
        module Event
          def self.included(base)
            base.include(ActiveSupport::Notifications::Event)
            base.extend(ClassMethods)
          end

          # Class methods for ActiveRecord events.
          module ClassMethods
            def span_options
              {}
            end

            def configuration
              Datadog.configuration.tracing[:active_record]
            end
          end
        end
      end
    end
  end
end
