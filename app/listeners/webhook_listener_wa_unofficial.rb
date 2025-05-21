module WebhookListenerWaUnofficial
  def perform(inbox, payload)
    webhook_url = inbox.channel.webhook_url
    uri = URI.parse(webhook_url)
    params = URI.decode_www_form(uri.query).to_h
    params['incoming_message'] = 'jangkau'
    uri.query = URI.encode_www_form(params)
    modified_webhook_url = uri.to_s
    Rails.logger.info("modified_webhook_url to send: #{modified_webhook_url}")
    WebhookJob.perform_later(modified_webhook_url, payload, :api_inbox_webhook)
  end
end
