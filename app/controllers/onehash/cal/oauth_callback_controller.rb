class Onehash::Cal::OauthCallbackController < ApplicationController
  def callback
    token_response = get_oauth_token(params[:code])

    set_current_account_user(params[:state])
    handle_oauth_token(token_response)

    redirect_to "/app/accounts/#{Current.account_user.account.id}/settings/integrations/onehash_apps"
    # render json: { message: 'OAuth flow successful', token_response: token_response }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def get_oauth_token(code)
    client_id = ENV.fetch('ONEHASH_CAL_CLIENT_ID', nil)
    client_secret = ENV.fetch('ONEHASH_CAL_CLIENT_SECRET', nil)
    redirect_uri = ENV.fetch('ONEHASH_CAL_OAUTH_REDIRECT_URL', nil)

    # TODO: CAL
    url = "#{ENV.fetch('ONEHASH_CAL_APP_ORIGIN_URL', nil)}/api/auth/oauth/token"
    # url = 'http://localhost:3001/api/auth/oauth/token'

    response = RestClient.post(url, {
                                 client_id: client_id,
                                 client_secret: client_secret,
                                 code: code,
                                 redirect_uri: redirect_uri,
                                 grant_type: 'authorization_code'
                               })
    JSON.parse(response.body)
  end

  # Method to set the current account user based on the state parameter
  def set_current_account_user(state_param)
    # Parse the state parameter (URL-decoded JSON string)
    parsed_state_param = begin
      JSON.parse(URI.decode_www_form_component(state_param))
    rescue StandardError => e
      logger.error "Failed to parse state parameter: #{e.message}"
      {}
    end

    # Extract account_user_id from the parsed state
    account_user_id = parsed_state_param['account_user_id']

    # If account_user_id is present, set the Current.account_user
    if account_user_id.present?
      Current.account_user = AccountUser.find(account_user_id)
      logger.info "Set Current.account_user to ID #{account_user_id}"
    else
      logger.warn 'No account_user_id found in the state parameter. Unable to set Current.account_user.'
    end
  end

  # Create hook from access token
  def handle_oauth_token(token_response)
    access_token = ENV.fetch('ONEHASH_API_KEY', nil)
    hook = Integrations::Hook.create(
      access_token: access_token,
      hook_type: 'account_user',
      account_user: Current.account_user,
      account: Current.account_user.account,
      inbox_id: nil,
      app_id: 'onehash_cal',
      settings: { cal_user_id: token_response['cal_user_id'] },
      status: 'enabled'
    )

    if hook.persisted?
      Rails.logger.info 'Hook created successfully!'
    else
      Rails.logger.error "Failed to create hook: #{hook.errors.full_messages.join(', ')}"
    end
  end
end
