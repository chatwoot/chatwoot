class NotificaMe::WebhookSetupService
  include Rails.application.routes.url_helpers

  pattr_initialize [:inbox!]

  def perform
    url = 'https://hub.notificame.com.br/v1/subscriptions'
    response = HTTParty.post(
      url,
      body: {
        webhook: {
          url: inbox.callback_webhook_url
        },
        criteria: {
          channel: channel.notifica_me_id
        }
      }.to_json,
      headers: {
        'X-API-Token' => channel.notifica_me_token,
        'Content-Type' => 'application/json'
      }
    )

    if !response.success?
      raise "Error on setup NotificaMe webhook: #{response.parsed_response}"
    end
  end

  private

  def channel
    @channel ||= inbox.channel
  end
end
