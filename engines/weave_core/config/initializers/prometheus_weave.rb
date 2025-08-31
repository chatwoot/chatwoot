require 'prometheus/client'

PROM_REGISTRY = Prometheus::Client.registry

HTTP_REQUEST_TOTAL = PROM_REGISTRY.counter(:wsc_http_requests_total, 'Total HTTP requests', labels: [:controller, :action, :status])
HTTP_REQUEST_DURATION = PROM_REGISTRY.histogram(:wsc_http_request_duration_seconds, 'HTTP request duration (s)', labels: [:controller, :action, :status], buckets: [0.05, 0.1, 0.2, 0.3, 0.6, 1, 2, 5])

ActiveSupport::Notifications.subscribe('process_action.action_controller') do |name, start, finish, id, payload|
  controller = payload[:controller]
  action = payload[:action]
  status = payload[:status].to_s
  duration = (finish - start).to_f

  HTTP_REQUEST_TOTAL.increment(labels: { controller: controller, action: action, status: status })
  HTTP_REQUEST_DURATION.observe(duration, labels: { controller: controller, action: action, status: status })
end

