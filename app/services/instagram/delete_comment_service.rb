class Instagram::DeleteCommentService
  def initialize(message)
    @message = message
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

    delete_comment(access_token, app_secret_proof)
    true
  rescue StandardError => e
    Rails.logger.error("Instagram comment deletion failed: #{e.message}")
    false
  end

  private

  def delete_comment(access_token, app_secret_proof)
    query = { access_token: access_token }
    query[:appsecret_proof] = app_secret_proof if app_secret_proof

    response = HTTParty.delete(
      "https://graph.facebook.com/#{@message.content_attributes['comment_id']}",
      query: query
    )

    return if response.parsed_response['error'].blank?

    Rails.logger.error("Instagram comment deletion failed: #{response.parsed_response['error']}")
    raise StandardError, response.parsed_response['error']['message']
  end
end
