class AgentBotListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    return unless message.reportable? && inbox.agent_bot_inbox.present?
    return unless inbox.agent_bot_inbox.active?

    agent_bot = inbox.agent_bot_inbox.agent_bot

    payload = message.webhook_data.merge(event: __method__.to_s)
    AgentBotJob.perform_later(agent_bot.outgoing_url, payload)
  end
end
