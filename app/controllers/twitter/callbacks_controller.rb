class Twitter::CallbacksController < Twitter::BaseController
  def show
    return redirect_to twitter_app_redirect_url if permitted_params[:denied]

    @response = twitter_client.access_token(
      oauth_token: permitted_params[:oauth_token],
      oauth_verifier: permitted_params[:oauth_verifier]
    )
    if @response.status == '200'
      inbox = build_inbox
      ::Redis::Alfred.delete(permitted_params[:oauth_token])
      ::Twitter::WebhookSubscribeService.new(inbox_id: inbox.id).perform
      redirect_to app_twitter_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
    else
      redirect_to twitter_app_redirect_url
    end
  end

  private

  def parsed_body
    @parsed_body ||= Rack::Utils.parse_nested_query(@response.raw_response.body)
  end

  def account_id
    ::Redis::Alfred.get(permitted_params[:oauth_token])
  end

  def account
    @account ||= Account.find_by!(id: account_id)
  end

  def twitter_app_redirect_url
    app_new_twitter_inbox_url(account_id: account.id)
  end

  def build_inbox
    ActiveRecord::Base.transaction do
      twitter_profile = account.twitter_profiles.create(
        twitter_access_token: parsed_body['oauth_token'],
        twitter_access_token_secret: parsed_body['oauth_token_secret'],
        profile_id: parsed_body['user_id']
      )
      account.inboxes.create(
        name: parsed_body['screen_name'],
        channel: twitter_profile
      )
    rescue StandardError => e
      Rails.logger e
    end
  end

  def permitted_params
    params.permit(:oauth_token, :oauth_verifier, :denied)
  end
end
