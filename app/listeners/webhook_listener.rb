class WebhookListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.reportable? && inbox.webhook.present?

    webhook = message.inbox.webhook
    payload = message.push_event_data.merge(event: __method__.to_s)

    webhook.urls.each do |url|
      WebhookJob.perform_later(url, payload)
    end
  end
end
