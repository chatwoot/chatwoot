# frozen_string_literal: true

module TestProf
  module EventProf
    # Registers and activates custom events (which require patches).
    module CustomEvents
      class << self
        def register(event, &block)
          raise ArgumentError, "Block is required!" unless block
          registrations[event] = block
        end

        def activate_all(events)
          events = events.split(",")
          events.each { |event| try_activate(event) }
        end

        def try_activate(event)
          return unless registrations.key?(event)
          registrations.delete(event).call
        end

        private

        def registrations
          @registrations ||= {}
        end
      end
    end
  end
end

require "test_prof/event_prof/custom_events/factory_create"
require "test_prof/event_prof/custom_events/sidekiq_inline"
require "test_prof/event_prof/custom_events/sidekiq_jobs"
