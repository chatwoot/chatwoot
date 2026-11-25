class AgentBotListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    payload = conversation.webhook_data.merge(event: __method__.to_s)
    deliver(conversation.inbox, conversation, payload)
  end

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]
    payload = conversation.webhook_data.merge(event: __method__.to_s)
    deliver(conversation.inbox, conversation, payload)
  end

  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver(conversation.inbox, conversation, payload)
  end

  def conversation_updated(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver(conversation.inbox, conversation, payload)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless message.webhook_sendable?

    deliver(message.inbox, message.conversation, message.webhook_data.merge(event: __method__.to_s))
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    return unless message.webhook_sendable?

    deliver(message.inbox, message.conversation, message.webhook_data.merge(event: __method__.to_s))
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    payload = contact_inbox.webhook_data.merge(event: __method__.to_s)
    payload[:event_info] = event.data[:event_info]
    deliver(contact_inbox.inbox, nil, payload)
  end

  # Only a change of `connection` reaches the bots: the same event also fires for every new QR,
  # error and epoch while pairing. The payload is the agent half of provider_connection; the QR
  # and the error grant access to the WhatsApp account and stay admin-only. `changed_at` is when
  # the write happened, which is what orders two changes whose deliveries arrive out of order
  # (a retry is signed when it is sent, so the signature timestamp cannot).
  def inbox_provider_connection_updated(event)
    inbox = event.data[:inbox]
    provider_connection = event.data[:provider_connection] || {}
    previous_connection = event.data[:previous_connection]
    return if provider_connection['connection'] == previous_connection

    payload = {
      event: __method__.to_s,
      account: { id: inbox.account_id },
      inbox: { id: inbox.id, name: inbox.name, channel_type: inbox.channel_type, provider: inbox.channel.provider },
      provider_connection: inbox.channel.provider_connection_agent_data(provider_connection),
      previous_connection: previous_connection,
      changed_at: event.timestamp.utc.iso8601(6)
    }
    deliver(inbox, nil, payload)
  end

  private

  # The responders first (the conversation's own bot and the inbox's), then the observers the
  # responders did not already cover. Each role travels under its own webhook type, which is what
  # keeps a failing observer from handing a conversation it does not own to a human
  # (Webhooks::Trigger#handle_error, Webhooks::ErrorHandler). See AgentBotObserver.
  def deliver(inbox, conversation, payload)
    responders = agent_bots_for(inbox, conversation)
    responders.each { |agent_bot| process_webhook_bot_event(agent_bot, payload, :agent_bot_webhook) }
    (observer_agent_bots_for(inbox) - responders).each do |agent_bot|
      process_webhook_bot_event(agent_bot, payload, :agent_bot_observer_webhook)
    end
  end

  def agent_bots_for(inbox, conversation = nil)
    bots = [active_inbox_agent_bot(inbox)]
    bots << conversation.ai_assignee if conversation&.assignee_type == 'AgentBot'

    bots.compact.uniq
  end

  def active_inbox_agent_bot(inbox)
    return unless inbox.agent_bot_inbox&.active?

    inbox.agent_bot
  end

  # Through the join, so an observer row whose bot is already gone (AgentBot#agent_bot_observers is
  # destroyed asynchronously) is not delivered to as a nil. Queried rather than read off the
  # association, which an earlier read in the same request may have cached before the row existed.
  def observer_agent_bots_for(inbox)
    AgentBot.joins(:agent_bot_observers).where(agent_bot_observers: { inbox_id: inbox.id }).to_a
  end

  def process_webhook_bot_event(agent_bot, payload, webhook_type)
    # Only webhook bots are supported
    return if agent_bot.outgoing_url.blank?

    AgentBots::WebhookJob.perform_later(agent_bot.outgoing_url, payload, webhook_type,
                                        secret: agent_bot.secret, delivery_id: SecureRandom.uuid)
  end
end
