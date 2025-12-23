# frozen_string_literal: true

require_relative '../notifications/event'

module Datadog
  module Tracing
    module Contrib
      module ActiveSupport
        module Cache
          # Defines basic behaviors for an ActiveSupport event.
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
                Datadog.configuration.tracing[:active_support]
              end
            end
          end
        end
      end
    end
  end
end
