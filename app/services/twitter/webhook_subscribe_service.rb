class Twitter::WebhookSubscribeService
  include Rails.application.routes.url_helpers

  pattr_initialize [:inbox_id]

  def perform
    register_response = twitter_client.register_webhook(url: webhooks_twitter_url(protocol: 'https'))
    twitter_client.subscribe_webhook if register_response.status == '200'
    Rails.logger.info 'TWITTER_REGISTER_WEBHOOK_FAILURE: ' + register_response.body.to_s
  end

  private

  delegate :channel, to: :inbox
  delegate :twitter_client, to: :channel

  def inbox
    Inbox.find_by!(id: inbox_id)
  end
end
