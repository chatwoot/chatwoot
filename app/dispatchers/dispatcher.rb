class Dispatcher
  include Singleton

  WEBHOOK_ACTOR_EVENTS = %w[
    conversation.created conversation.updated conversation.status_changed conversation.opened conversation.resolved
    message.created message.updated
  ].freeze

  attr_reader :async_dispatcher, :sync_dispatcher

  def self.dispatch(event_name, timestamp, data, async = false)
    Rails.configuration.dispatcher.dispatch(event_name, timestamp, data, async)
  end

  def initialize
    @sync_dispatcher = SyncDispatcher.new
    @async_dispatcher = AsyncDispatcher.new
  end

  def dispatch(event_name, timestamp, data, _async = false)
    if WEBHOOK_ACTOR_EVENTS.include?(event_name.to_s)
      resource = data[:conversation] || data[:message]
      actor = data[:performed_by] || Current.user
      data = data.merge(webhook_actor: Webhooks::EventActor.serialize(actor, resource.account_id))
    end

    @sync_dispatcher.dispatch(event_name, timestamp, data)
    @async_dispatcher.dispatch(event_name, timestamp, data)
  end

  def load_listeners
    @sync_dispatcher.load_listeners
    @async_dispatcher.load_listeners
  end
end
