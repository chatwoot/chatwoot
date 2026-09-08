module Api::V1::Accounts::Concerns::InboxSecretManagement
  extend ActiveSupport::Concern

  def reset_secret
    return head :not_found unless @inbox.api?

    @inbox.channel.reset_secret!
  end

  def rotate_hmac_token
    return head :not_found unless @inbox.web_widget? || @inbox.api?

    @inbox.channel.regenerate_hmac_token
    render :show
  end
end
