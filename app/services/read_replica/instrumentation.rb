class ReadReplica::Instrumentation
  EVENT_NAME = 'read_replica.route'.freeze

  class << self
    def instrument(controller:, action:, selection:, &)
      payload = {
        controller: controller,
        action: action,
        role: selection.role,
        reason: selection.reason,
        lag_seconds: selection.lag_seconds
      }

      add_new_relic_attributes(payload)
      ActiveSupport::Notifications.instrument(EVENT_NAME, payload, &)
    end

    private

    def add_new_relic_attributes(payload)
      return unless defined?(::NewRelic::Agent)
      return unless ::NewRelic::Agent.respond_to?(:add_custom_attributes)

      ::NewRelic::Agent.add_custom_attributes(payload.compact.transform_keys { |key| "read_replica_#{key}" })
    rescue StandardError
      nil
    end
  end
end
