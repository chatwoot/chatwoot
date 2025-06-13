class SyncDispatcher < BaseDispatcher
  def dispatch(event_name, timestamp, data)
    event_object = Events::Base.new(event_name, timestamp, data)
    publish(event_object.method_name, event_object)
  end

  def listeners
    [ActionCableListener.instance, AgentBotListener.instance, WebhookListener.instance]
  end

  def publish(event_name, event_object)
    listeners.each do |listener|
      next if listener.is_a?(WebhookListener) && !event_object.sync_webhook?

      listener.public_send(event_name, event_object) if listener.respond_to?(event_name)
    end
  end
end
