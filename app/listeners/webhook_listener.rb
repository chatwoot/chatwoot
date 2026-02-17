class WebhookListener < BaseListener
  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    inbox = conversation.inbox
    idempotency_key = generate_idempotency_key(__method__.to_s, conversation)
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes, idempotency_key: idempotency_key)
    deliver_webhook_payloads(payload, inbox, idempotency_key)
  end

  def conversation_updated(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    inbox = conversation.inbox
    idempotency_key = generate_idempotency_key(__method__.to_s, conversation)
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes, idempotency_key: idempotency_key)
    deliver_webhook_payloads(payload, inbox, idempotency_key)
  end

  def conversation_created(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    idempotency_key = generate_idempotency_key(__method__.to_s, conversation)
    payload = conversation.webhook_data.merge(event: __method__.to_s, idempotency_key: idempotency_key)
    deliver_webhook_payloads(payload, inbox, idempotency_key)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.webhook_sendable?

    idempotency_key = generate_idempotency_key(__method__.to_s, message)
    payload = message.webhook_data.merge(event: __method__.to_s, idempotency_key: idempotency_key)
    deliver_webhook_payloads(payload, inbox, idempotency_key)
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.webhook_sendable?

    idempotency_key = generate_idempotency_key(__method__.to_s, message)
    payload = message.webhook_data.merge(event: __method__.to_s, idempotency_key: idempotency_key)
    deliver_webhook_payloads(payload, inbox, idempotency_key)
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    inbox = contact_inbox.inbox

    idempotency_key = generate_idempotency_key(__method__.to_s, contact_inbox)
    payload = contact_inbox.webhook_data.merge(event: __method__.to_s, idempotency_key: idempotency_key)
    payload[:event_info] = event.data[:event_info]
    deliver_webhook_payloads(payload, inbox, idempotency_key)
  end

  def contact_created(event)
    contact, account = extract_contact_and_account(event)
    idempotency_key = generate_idempotency_key(__method__.to_s, contact)
    payload = contact.webhook_data.merge(event: __method__.to_s, idempotency_key: idempotency_key)
    deliver_account_webhooks(payload, account, idempotency_key)
  end

  def contact_updated(event)
    contact, account = extract_contact_and_account(event)
    changed_attributes = extract_changed_attributes(event)
    return if changed_attributes.blank?

    idempotency_key = generate_idempotency_key(__method__.to_s, contact)
    payload = contact.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes, idempotency_key: idempotency_key)
    deliver_account_webhooks(payload, account, idempotency_key)
  end

  def inbox_created(event)
    inbox, account = extract_inbox_and_account(event)
    inbox_webhook_data = Inbox::EventDataPresenter.new(inbox).push_data
    idempotency_key = generate_idempotency_key(__method__.to_s, inbox)
    payload = inbox_webhook_data.merge(event: __method__.to_s, idempotency_key: idempotency_key)
    deliver_account_webhooks(payload, account, idempotency_key)
  end

  def inbox_updated(event)
    inbox, account = extract_inbox_and_account(event)
    changed_attributes = extract_changed_attributes(event)
    return if changed_attributes.blank?

    inbox_webhook_data = Inbox::EventDataPresenter.new(inbox).push_data
    idempotency_key = generate_idempotency_key(__method__.to_s, inbox)
    payload = inbox_webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes, idempotency_key: idempotency_key)
    deliver_account_webhooks(payload, account, idempotency_key)
  end

  def conversation_typing_on(event)
    handle_typing_status(__method__.to_s, event)
  end

  def conversation_typing_off(event)
    handle_typing_status(__method__.to_s, event)
  end

  def agent_added(event)
    agent, account = extract_agent_and_account(event)
    idempotency_key = generate_idempotency_key(__method__.to_s, agent)
    payload = agent.webhook_create_data.merge(event: __method__.to_s, idempotency_key: idempotency_key)
    deliver_account_webhooks(payload, account, idempotency_key)
  end

  # FAQ catalog bulk event
  def faq_catalog_updated(event)
    account = event.data[:account]
    added_count = event.data[:added_count] || 0
    updated_count = event.data[:updated_count] || 0
    deleted_count = event.data[:deleted_count] || 0
    added_faq_items = event.data[:added_faq_items] || []
    updated_faq_items = event.data[:updated_faq_items] || []
    deleted_faq_items = event.data[:deleted_faq_items] || []

    idempotency_key = SecureRandom.uuid
    payload = {
      event: __method__.to_s,
      timestamp: Time.zone.now.iso8601,
      account: account.webhook_data,
      added_count: added_count,
      updated_count: updated_count,
      deleted_count: deleted_count,
      added_faq_items: added_faq_items,
      updated_faq_items: updated_faq_items,
      deleted_faq_items: deleted_faq_items,
      idempotency_key: idempotency_key
    }
    deliver_account_webhooks(payload, account, idempotency_key)
  end

  # Product catalog bulk event
  def product_catalog_updated(event)
    account = event.data[:account]
    added_count = event.data[:added_count] || 0
    updated_count = event.data[:updated_count] || 0
    deleted_count = event.data[:deleted_count] || 0
    added_product_ids = event.data[:added_product_ids] || []
    updated_product_ids = event.data[:updated_product_ids] || []
    deleted_product_ids = event.data[:deleted_product_ids] || []

    idempotency_key = SecureRandom.uuid
    payload = {
      event: __method__.to_s,
      timestamp: Time.zone.now.iso8601,
      account: account.webhook_data,
      added_count: added_count,
      updated_count: updated_count,
      deleted_count: deleted_count,
      added_product_ids: added_product_ids,
      updated_product_ids: updated_product_ids,
      deleted_product_ids: deleted_product_ids,
      idempotency_key: idempotency_key
    }
    deliver_account_webhooks(payload, account, idempotency_key)
  end

  # KB Resource event
  def kb_resource_updated(event)
    account = event.data[:account]
    action = event.data[:action]
    resource = event.data[:resource]

    idempotency_key = SecureRandom.uuid
    payload = {
      event: __method__.to_s,
      timestamp: Time.zone.now.iso8601,
      account: account.webhook_data,
      action: action,
      resource: resource,
      idempotency_key: idempotency_key
    }
    deliver_account_webhooks(payload, account, idempotency_key)
  end

  private

  def handle_typing_status(event_name, event)
    conversation = event.data[:conversation]
    user = event.data[:user]
    inbox = conversation.inbox

    idempotency_key = generate_idempotency_key(event_name, conversation)
    payload = {
      event: event_name,
      user: user.webhook_data,
      conversation: conversation.webhook_data,
      is_private: event.data[:is_private] || false,
      idempotency_key: idempotency_key
    }
    deliver_webhook_payloads(payload, inbox, idempotency_key)
  end

  def deliver_account_webhooks(payload, account, idempotency_key)
    account.webhooks.account_type.each do |webhook|
      next unless webhook.subscriptions.include?(payload[:event])

      WebhookJob.perform_later(webhook.url, payload, :account_webhook, idempotency_key)
    end
  end

  def deliver_api_inbox_webhooks(payload, inbox, idempotency_key)
    return unless inbox.channel_type == 'Channel::Api'
    return if inbox.channel.webhook_url.blank?

    WebhookJob.perform_later(inbox.channel.webhook_url, payload, :api_inbox_webhook, idempotency_key)
  end

  def deliver_webhook_payloads(payload, inbox, idempotency_key)
    deliver_account_webhooks(payload, inbox.account, idempotency_key)
    deliver_api_inbox_webhooks(payload, inbox, idempotency_key)
  end

  def generate_idempotency_key(event_name, resource)
    return SecureRandom.uuid unless resource.respond_to?(:id) && resource.respond_to?(:updated_at)

    Digest::SHA256.hexdigest("#{event_name}-#{resource.class.name}-#{resource.id}-#{resource.updated_at.to_i}")
  end
end
