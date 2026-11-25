class WebhookListener < BaseListener
  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver_webhook_payloads(payload, inbox)
  end

  def conversation_updated(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver_webhook_payloads(payload, inbox)
  end

  def conversation_created(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s)
    deliver_webhook_payloads(payload, inbox)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.webhook_sendable?

    payload = message.webhook_data.merge(event: __method__.to_s)
    deliver_webhook_payloads(payload, inbox)

    message_incoming(event)
    message_outgoing(event)
  end

  def message_incoming(event)
    message = extract_message_and_account(event)[0]

    return unless message.webhook_sendable?
    return unless message.incoming?

    payload = message.webhook_data.merge(event: __method__.to_s)
    deliver_account_webhooks(payload, message.account)
  end

  def message_outgoing(event)
    message = extract_message_and_account(event)[0]

    return unless message.webhook_sendable?
    return unless message.outgoing?

    payload = message.webhook_data.merge(event: __method__.to_s)
    deliver_account_webhooks(payload, message.account)
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.webhook_sendable?

    payload = message.webhook_data.merge(event: __method__.to_s)
    deliver_webhook_payloads(payload, inbox)
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    inbox = contact_inbox.inbox

    payload = contact_inbox.webhook_data.merge(event: __method__.to_s)
    payload[:event_info] = event.data[:event_info]
    deliver_webhook_payloads(payload, inbox)
  end

  def contact_created(event)
    contact, account = extract_contact_and_account(event)
    payload = contact.webhook_data.merge(event: __method__.to_s)
    deliver_account_webhooks(payload, account)
  end

  def contact_updated(event)
    contact, account = extract_contact_and_account(event)
    changed_attributes = extract_changed_attributes(event)
    return if changed_attributes.blank?

    payload = contact.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver_account_webhooks(payload, account)
  end

  def inbox_created(event)
    inbox, account = extract_inbox_and_account(event)
    inbox_webhook_data = Inbox::EventDataPresenter.new(inbox).webhook_data
    payload = inbox_webhook_data.merge(event: __method__.to_s)
    deliver_account_webhooks(payload, account)
  end

  def inbox_updated(event)
    inbox, account = extract_inbox_and_account(event)
    changed_attributes = extract_changed_attributes(event)
    return if changed_attributes.blank?

    inbox_webhook_data = Inbox::EventDataPresenter.new(inbox).webhook_data
    payload = inbox_webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver_account_webhooks(payload, account)
  end

  def conversation_typing_on(event)
    handle_typing_status(__method__.to_s, event)
  end

  def conversation_typing_off(event)
    handle_typing_status(__method__.to_s, event)
  end

  def conversation_recording(event)
    handle_typing_status(__method__.to_s, event)
  end

  %i[internal_chat_message_created internal_chat_message_updated internal_chat_message_deleted].each do |event_name|
    define_method(event_name) do |event|
      message = event.data[:message]
      payload = internal_chat_message_payload(message).merge(event: event_name.to_s)
      deliver_account_webhooks(payload, message.account)
    end
  end

  def internal_chat_channel_updated(event)
    channel = event.data[:channel]
    payload = internal_chat_channel_payload(channel).merge(event: __method__.to_s)
    deliver_account_webhooks(payload, channel.account)
  end

  def provider_event_received(event)
    inbox, account = extract_inbox_and_account(event)

    payload = {
      event: __method__.to_s,
      inbox: inbox.webhook_data,
      account: account.webhook_data,
      provider_event: event.data[:event],
      provider_event_data: event.data[:payload]
    }
    deliver_account_webhooks(payload, account)
  end

  private

  def handle_typing_status(event_name, event)
    conversation = event.data[:conversation]
    user = event.data[:user]
    inbox = conversation.inbox

    payload = {
      event: event_name,
      user: user.webhook_data,
      conversation: conversation.webhook_data,
      is_private: event.data[:is_private] || false
    }
    deliver_webhook_payloads(payload, inbox)
  end

  def internal_chat_message_payload(message)
    {
      id: message.id,
      content: message.content,
      content_type: message.content_type,
      internal_chat_channel_id: message.internal_chat_channel_id,
      sender: message.sender&.push_event_data,
      account_id: message.account_id,
      created_at: message.created_at,
      updated_at: message.updated_at
    }
  end

  def internal_chat_channel_payload(channel)
    {
      id: channel.id,
      name: channel.name,
      channel_type: channel.channel_type,
      account_id: channel.account_id,
      created_at: channel.created_at,
      updated_at: channel.updated_at
    }
  end

  def deliver_account_webhooks(payload, account)
    return unless account.api_and_webhooks_enabled?

    account.webhooks.account_type.each do |webhook|
      next unless webhook.subscriptions.include?(payload[:event])
      next if payload[:inbox].present? && webhook.inbox_id.present? && webhook.inbox_id != payload[:inbox][:id]

      WebhookJob.perform_later(webhook.url, payload, :account_webhook,
                               secret: webhook.secret,
                               delivery_id: SecureRandom.uuid)
    end
  end

  def deliver_api_inbox_webhooks(payload, inbox)
    return unless inbox.channel_type == 'Channel::Api'
    return if inbox.channel.webhook_url.blank?

    WebhookJob.perform_later(inbox.channel.webhook_url, payload, :api_inbox_webhook,
                             secret: inbox.channel.secret, delivery_id: SecureRandom.uuid)
  end

  def deliver_webhook_payloads(payload, inbox)
    deliver_account_webhooks(payload, inbox.account)
    deliver_api_inbox_webhooks(payload, inbox)
  end
end
