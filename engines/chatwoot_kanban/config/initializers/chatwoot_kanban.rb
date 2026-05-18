# This initializer is loaded automatically by the host through the engine's
# eager-load path. It does two things:
#   1) wires the conversation listener into Chatwoot's dispatcher
#   2) adds Rack::Attack throttles for the heavy "move card" endpoint
#
# Tweak ChatwootKanban.configure in your host config/initializers if you need
# to disable the auto-create listener or change defaults.

Rails.application.config.after_initialize do
  if defined?(Rails.configuration.dispatcher) && Rails.configuration.dispatcher
    begin
      Rails.configuration.dispatcher.attach_listener(
        ChatwootKanban::ConversationListener.instance
      )
    rescue StandardError => e
      Rails.logger.warn("[ChatwootKanban] could not attach listener: #{e.message}")
    end
  end
end

if defined?(Rack::Attack)
  Rack::Attack.throttle('kanban/move-card', limit: 60, period: 1.minute) do |req|
    if req.path =~ %r{\A/api/v1/accounts/\d+/kanban/boards/\d+/cards/move\z} && req.patch?
      # Throttle key: API token (or IP fallback)
      req.env['HTTP_API_ACCESS_TOKEN'] || req.ip
    end
  end

  Rack::Attack.throttle('kanban/writes', limit: 300, period: 1.minute) do |req|
    if req.path.include?('/kanban/') && (req.post? || req.patch? || req.delete?)
      req.env['HTTP_API_ACCESS_TOKEN'] || req.ip
    end
  end
end
