# Extend existing Lograge JSON logs with tenantId and traceId without editing core
if defined?(Lograge)
  Rails.application.configure do
    # Only active when Lograge is enabled via env in the host app
    if ActiveModel::Type::Boolean.new.cast(ENV.fetch('LOGRAGE_ENABLED', false))
      old_payload = config.lograge.custom_payload
      old_options = config.lograge.custom_options

      config.lograge.custom_payload = lambda do |controller|
        base = old_payload ? old_payload.call(controller) : {}
        tenant_id = nil
        begin
          tenant_id = Current.account&.id if defined?(Current)
        rescue StandardError
          tenant_id = nil
        end
        trace_id = controller.request.request_id
        base.merge({ tenantId: tenant_id, traceId: trace_id })
      end

      config.lograge.custom_options = lambda do |event|
        base = old_options ? old_options.call(event) : {}
        # Attempt to read request id from payload; fall back to tags/uuid if present
        trace_id = event.payload[:request_id] || event.payload[:trace_id]
        base.merge({ traceId: trace_id })
      end
    end
  end
end

