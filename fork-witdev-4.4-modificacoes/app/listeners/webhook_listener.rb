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
    inbox_webhook_data = Inbox::EventDataPresenter.new(inbox).push_data
    payload = inbox_webhook_data.merge(event: __method__.to_s)
    deliver_account_webhooks(payload, account)
  end

  def inbox_updated(event)
    inbox, account = extract_inbox_and_account(event)
    changed_attributes = extract_changed_attributes(event)
    return if changed_attributes.blank?

    inbox_webhook_data = Inbox::EventDataPresenter.new(inbox).push_data
    payload = inbox_webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver_account_webhooks(payload, account)
  end

  def conversation_typing_on(event)
    handle_typing_status(__method__.to_s, event)
  end

  def conversation_typing_off(event)
    handle_typing_status(__method__.to_s, event)
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

  def deliver_account_webhooks(payload, account)
    webhooks = account.webhooks.account_type.where('subscriptions @> ?', [payload[:event]].to_json)
    
    Rails.logger.info "[WEBHOOK] Account #{account.id}: Found #{webhooks.count} webhooks for event '#{payload[:event]}'"
    
    webhooks.each do |webhook|
      Rails.logger.info "[WEBHOOK] Processing webhook ID #{webhook.id} - URL: #{webhook.url}"
      Rails.logger.info "[WEBHOOK] Include access token: #{webhook.include_access_token}"

      final_payload = payload.dup
      
      # Incluir ACCESS_TOKEN se o webhook estiver configurado para isso
      if webhook.include_access_token
        administrator = account.administrators.first
        access_token = administrator&.access_token&.token
        
        Rails.logger.info "[WEBHOOK] Administrator found: #{administrator.present?}"
        Rails.logger.info "[WEBHOOK] Access token available: #{access_token.present?}"
        
        if access_token
          final_payload[:ACCESS_TOKEN] = access_token
          Rails.logger.info "[WEBHOOK] ACCESS_TOKEN added to payload"
        else
          Rails.logger.warn "[WEBHOOK] ACCESS_TOKEN requested but not available - Administrator: #{administrator.present?}, Token: #{access_token.present?}"
        end
      end

      # Incluir dados do SocialWise se estiver ativo
      Rails.logger.info "[WEBHOOK] Calling Socialwise enhancement for account #{account.id}"
      original_payload_keys = final_payload.keys.count
      final_payload = Integrations::Socialwise::WebhookEnhancerService.enhance_payload(final_payload, account)
      enhanced_payload_keys = final_payload.keys.count
      Rails.logger.info "[WEBHOOK] Socialwise enhancement result: #{original_payload_keys} -> #{enhanced_payload_keys} keys"
      Rails.logger.info "[WEBHOOK] Socialwise data present: #{final_payload.key?('socialwise-chatwit')}"

      begin
        WebhookJob.perform_later(webhook.url, final_payload)
        Rails.logger.info "[WEBHOOK] Job enqueued successfully for webhook ID #{webhook.id}"
      rescue => e
        Rails.logger.error "[WEBHOOK] Failed to enqueue job for webhook ID #{webhook.id}: #{e.message}"
      end
    end
  end

  def deliver_api_inbox_webhooks(payload, inbox)
    return unless inbox.channel_type == 'Channel::Api'
    return if inbox.channel.webhook_url.blank?

    Rails.logger.info "[WEBHOOK] Delivering to API inbox webhook: #{inbox.channel.webhook_url}"
    
    # Incluir dados do SocialWise se estiver ativo
    enhanced_payload = Integrations::Socialwise::WebhookEnhancerService.enhance_payload(payload, inbox.account)
    
    WebhookJob.perform_later(inbox.channel.webhook_url, enhanced_payload, :api_inbox_webhook)
  end

  def deliver_webhook_payloads(payload, inbox)
    deliver_account_webhooks(payload, inbox.account)
    deliver_api_inbox_webhooks(payload, inbox)
  end
end
