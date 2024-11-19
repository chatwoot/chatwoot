class Twitter::WebhookSubscribeService
  include Rails.application.routes.url_helpers

  pattr_initialize [:inbox_id]

  def perform
    ensure_webhook
    unless subscription?
      subscribe_response = twitter_client.create_subscription
      raise StandardError, 'Twitter Subscription Failed' unless subscribe_response.status == '204'
    end

    true
  end

  private

  delegate :channel, to: :inbox
  delegate :twitter_client, to: :channel

  def inbox
    Inbox.find(inbox_id)
  end

  def twitter_url
    webhooks_twitter_url(protocol: 'https')
  end

  def ensure_webhook
    webhooks = fetch_webhooks
    return true if webhooks&.first&.try(:[], 'url') == twitter_url

    # twitter supports only one webhook url per environment
    # so we will delete the existing one if its not chatwoot
    unregister_webhook(webhooks.first) if webhooks&.first
    register_webhook
  end

  def unregister_webhook(webhook)
    unregister_response = twitter_client.unregister_webhook(id: webhook.try(:[], 'id'))
    Rails.logger.info "TWITTER_UNREGISTER_WEBHOOK: #{unregister_response.body}"
  end

  def register_webhook
    register_response = twitter_client.register_webhook(url: twitter_url)
    Rails.logger.info "TWITTER_REGISTER_WEBHOOK: #{register_response.body}"
  end

  def subscription?
    response = twitter_client.fetch_subscriptions
    response.status == '204'
  end

  def fetch_webhooks
    twitter_client.fetch_webhooks.body
  end
end
