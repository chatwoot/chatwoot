class Instagram::SendMessageService
  def initialize(message, comment_id = nil)
    @message = message
    @comment_id = comment_id
  end

  def calculate_app_secret_proof(app_secret, access_token)
    Facebook::Messenger::Configuration::AppSecretProofCalculator.call(
      app_secret, access_token
    )
  end

  def perform
    account_id = @message.account_id
    instagram_channel = Channel::FacebookPage.find_by(account_id: account_id)
    raise StandardError, 'Instagram channel not found' if instagram_channel.nil?

    access_token = instagram_channel.page_access_token
    app_secret_proof = calculate_app_secret_proof(GlobalConfigService.load('FB_APP_SECRET', ''), access_token)

    send_message(access_token, app_secret_proof)
    true
  rescue StandardError => e
    Rails.logger.error("Instagram message sending failed: #{e.message}")
    false
  end

  private

  def send_message(access_token, app_secret_proof)
    query = { access_token: access_token }
    query[:appsecret_proof] = app_secret_proof if app_secret_proof
    query[:comment_id] = @comment_id if @comment_id

    body = {
      recipient: { id: @message.conversation.contact_inbox.source_id },
      message: { text: @message.content }
    }

    response = HTTParty.post(
      'https://graph.facebook.com/v18.0/me/messages',
      query: query,
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    return if response.parsed_response['error'].blank?

    Rails.logger.error("Instagram message sending failed: #{response.parsed_response['error']}")
    raise StandardError, response.parsed_response['error']['message']
  end
end
