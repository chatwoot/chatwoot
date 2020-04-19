class Twitter::AuthorizationsController < Twitter::BaseController
  def create
    @response = twitter_client.request_oauth_token(url: twitter_callback_url)

    if @response.status == '200'
      ::Redis::Alfred.setex(oauth_token, account.id)
      redirect_to oauth_authorize_endpoint(oauth_token)
    else
      redirect_to app_new_twitter_inbox_url(account_id: account.id)
    end
  end

  private

  def oauth_token
    parsed_body['oauth_token']
  end

  def user
    @user ||= User.find_by(id: params[:user_id])
  end

  def account
    @account ||= user.account
  end

  def oauth_authorize_endpoint(oauth_token)
    "#{twitter_api_base_url}/oauth/authorize?oauth_token=#{oauth_token}"
  end
end
