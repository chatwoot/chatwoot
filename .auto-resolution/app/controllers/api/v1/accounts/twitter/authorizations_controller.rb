class Api::V1::Accounts::Twitter::AuthorizationsController < Api::V1::Accounts::BaseController
  include TwitterConcern

  before_action :check_authorization

  def create
    @response = twitter_client.request_oauth_token(url: twitter_callback_url)
    if @response.status == '200'
      ::Redis::Alfred.setex(oauth_token, Current.account.id)
      render json: { success: true, url: oauth_authorize_endpoint(oauth_token) }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def oauth_token
    parsed_body['oauth_token']
  end

  def oauth_authorize_endpoint(oauth_token)
    "#{twitter_api_base_url}/oauth/authorize?oauth_token=#{oauth_token}"
  end

  def check_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end
end
