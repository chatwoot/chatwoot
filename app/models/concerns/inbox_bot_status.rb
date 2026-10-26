module InboxBotStatus
  extend ActiveSupport::Concern

  def active_bot?
    external_bot_active?
  end

  def external_bot_active?
    agent_bot_active? || dialogflow_active?
  end

  def conflicting_bot_provider(provider)
    return 'Agent Bot' if provider != :agent_bot && agent_bot_active?
    return 'Dialogflow' if provider != :dialogflow && dialogflow_active?

    nil
  end

  private

  # Bot links can outlive their bot until async cleanup runs.
  def agent_bot_active?
    AgentBotInbox.active.joins(:agent_bot).exists?(inbox_id: id)
  end

  def dialogflow_active?
    hooks.exists?(app_id: %w[dialogflow], status: 'enabled')
  end
end
