require 'prometheus/client'

PROM_REGISTRY = Prometheus::Client.registry

HTTP_REQUEST_TOTAL = PROM_REGISTRY.counter(:wsc_http_requests_total, 'Total HTTP requests', labels: [:controller, :action, :status])
HTTP_REQUEST_DURATION = PROM_REGISTRY.histogram(:wsc_http_request_duration_seconds, 'HTTP request duration (s)', labels: [:controller, :action, :status, :read_write], buckets: [0.05, 0.1, 0.2, 0.3, 0.6, 1, 2, 5])

ActiveSupport::Notifications.subscribe('process_action.action_controller') do |name, start, finish, id, payload|
  controller = payload[:controller]
  action = payload[:action]
  status = payload[:status].to_s
  duration = (finish - start).to_f
  
  # Determine if this is a read or write operation
  read_write = case payload[:method].to_s.upcase
               when 'GET', 'HEAD', 'OPTIONS'
                 'read'
               when 'POST', 'PUT', 'PATCH', 'DELETE'
                 'write'
               else
                 'unknown'
               end

  HTTP_REQUEST_TOTAL.increment(labels: { controller: controller, action: action, status: status })
  HTTP_REQUEST_DURATION.observe(duration, labels: { controller: controller, action: action, status: status, read_write: read_write })
  
  # Log warning if exceeding performance budget SLAs
  sla_limit = read_write == 'read' ? 0.3 : 0.6  # 300ms for read, 600ms for write
  if duration > sla_limit
    Rails.logger.warn "[WSC Performance] #{read_write.upcase} operation exceeded SLA: #{(duration * 1000).round(2)}ms > #{(sla_limit * 1000).round(0)}ms (#{controller}##{action})"
  end
end

