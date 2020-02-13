class WebhookListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.reportable? && inbox.webhook.present?

    webhook = message.inbox.webhook
    payload = message.push_event_data

    webhook.urls.each do |url|
      Webhooks::Trigger.execute(url, payload)
    end
  end
end
