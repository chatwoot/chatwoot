# frozen_string_literal: true

# Z-API and uazapi call back on a URL that carries the inbox's webhook token as a path segment,
# because neither lets us set a header. filter_parameters only covers the params hash, so the
# token still reached the "Started POST" line and lograge's `path` (both read
# `request.filtered_path`) and Sentry's request URL (read from the Rack request).
#
# Declared here, and not as an autoloaded constant, so the module prepended to
# ActionDispatch::Request is the same object for the life of the process.
module WebhookTokenPathFilter
  PATTERN = %r{(/webhooks/whatsapp/(?:zapi|session/uazapi)/[^/?]+/)[^/?]+}
  MASK = '\1[FILTERED]'

  def self.filter(path)
    path&.sub(PATTERN, MASK)
  end

  def self.filter_sentry_event(event)
    event.request.url = filter(event.request.url) if event.request
    event.transaction = filter(event.transaction) if event.transaction
    event
  end

  module Request
    def filtered_path
      WebhookTokenPathFilter.filter(super)
    end
  end
end

ActiveSupport.on_load(:action_dispatch_request) { prepend WebhookTokenPathFilter::Request }

if defined?(Sentry) && Sentry.initialized?
  Sentry.configuration.before_send = Sentry.configuration.before_send.then do |previous|
    lambda do |event, hint|
      event = WebhookTokenPathFilter.filter_sentry_event(event)
      previous ? previous.call(event, hint) : event
    end
  end
  Sentry.configuration.before_send_transaction = Sentry.configuration.before_send_transaction.then do |previous|
    lambda do |event, hint|
      event = WebhookTokenPathFilter.filter_sentry_event(event)
      previous ? previous.call(event, hint) : event
    end
  end
end
