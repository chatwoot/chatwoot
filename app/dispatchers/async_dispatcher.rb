class AsyncDispatcher < BaseDispatcher
  def dispatch(event_name, timestamp, data)
    EventDispatcherJob.perform_later(event_name, timestamp, data)
  end

  def publish_event(event_name, timestamp, data)
    event_object = Events::Base.new(event_name, timestamp, data)
    publish(event_object.method_name, event_object)
  end

  def listeners
    [
      CampaignListener.instance,
      CsatSurveyListener.instance,
      EventListener.instance,
      HookListener.instance,
      InstallationWebhookListener.instance,
      NotificationListener.instance,
      WebhookListener.instance,
      AutomationRuleListener.instance
    ]
  end
end
