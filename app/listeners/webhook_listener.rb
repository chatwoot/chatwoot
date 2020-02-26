class WebhookListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.reportable?

    payload = message.webhook_data.merge(event: __method__.to_s)
    # Account webhooks
    inbox.account.webhooks.account.each do |webhook|
      WebhookJob.perform_later(webhook.url, payload)
    end

    # Inbox webhooks
    inbox.webhooks.inbox.each do |webhook|
      WebhookJob.perform_later(webhook.url, payload)
    end
  end
end
