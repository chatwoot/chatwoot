class Twitter::CallbacksController < Twitter::BaseController
  include TwitterConcern

  def show
    return redirect_to twitter_app_redirect_url if permitted_params[:denied]

    @response = ensure_access_token
    return redirect_to twitter_app_redirect_url if @response.status != '200'

    ActiveRecord::Base.transaction do
      inbox = create_inbox
      ::Redis::Alfred.delete(permitted_params[:oauth_token])
      ::Twitter::WebhookSubscribeService.new(inbox_id: inbox.id).perform
      redirect_to app_twitter_inbox_agents_url(account_id: account.id, inbox_id: inbox.id)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to twitter_app_redirect_url
  end

  private

  def parsed_body
    @parsed_body ||= Rack::Utils.parse_nested_query(@response.raw_response.body)
  end

  def account_id
    ::Redis::Alfred.get(permitted_params[:oauth_token])
  end

  def account
    @account ||= Account.find(account_id)
  end

  def twitter_app_redirect_url
    app_new_twitter_inbox_url(account_id: account.id)
  end

  def ensure_access_token
    twitter_client.access_token(
      oauth_token: permitted_params[:oauth_token],
      oauth_verifier: permitted_params[:oauth_verifier]
    )
  end

  def create_inbox
    twitter_profile = account.twitter_profiles.create!(
      twitter_access_token: parsed_body['oauth_token'],
      twitter_access_token_secret: parsed_body['oauth_token_secret'],
      profile_id: parsed_body['user_id']
    )
    inbox = account.inboxes.create!(
      name: parsed_body['screen_name'],
      channel: twitter_profile
    )
    save_profile_image(inbox)
    inbox
  end

  def save_profile_image(inbox)
    response = twitter_client.user_show(screen_name: inbox.name)

    return unless response.status.to_i == 200

    parsed_user_profile = response.body

    ::Avatar::AvatarFromUrlJob.perform_later(inbox, parsed_user_profile['profile_image_url_https'])
  end

  def permitted_params
    params.permit(:oauth_token, :oauth_verifier, :denied)
  end
end
