module InboxBotStatus
  extend ActiveSupport::Concern

  def active_bot?
    external_bot_active?
  end

  def external_bot_active?
    agent_bot_inbox&.active? || dialogflow_active?
  end

  def conflicting_bot_provider(provider)
    # Provider saves share this row lock, so concurrent connections cannot pass independently.
    self.class.lock.find(id)
    return 'Agent Bot' if provider != :agent_bot && AgentBotInbox.active.exists?(inbox_id: id)
    return 'Dialogflow' if provider != :dialogflow && dialogflow_active?

    nil
  end

  private

  def dialogflow_active?
    hooks.exists?(app_id: %w[dialogflow], status: 'enabled')
  end
end
