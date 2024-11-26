class Onehash::Cal::OauthController < Api::V1::Accounts::BaseController
  include RequestExceptionHandler

  def redirect
    oauth_url = build_oauth_url
    render json: { redirect_url: oauth_url }
  end

  def error
    render json: { error: 'OAuth authorization failed' }, status: :bad_request
  end

  def destroy
    Thread.current[:from_oauth_controller] = true

    account_user = Current.account_user

    Integrations::Hook.where(account_user_id: account_user.id, app_id: 'onehash_cal').destroy_all

    render json: { message: 'Account User hooks deleted successfully' }, status: :ok
  ensure
    Thread.current[:from_oauth_controller] = nil
  end

  private

  # Build the OAuth URL with the necessary parameters
  def build_oauth_url
    # http://localhost:3000/auth/oauth2/authorize
    # ?client_id=cd235bd04216961327a7c7af993fc5f30741e916017cd4000e4c554148add347
    # &state={%22team%22:%22disabled%22,%22email%22:%22arjun@onehash.ai%22}

    oauth_provider_url = ENV.fetch('ONEHASH_CAL_APP_ORIGIN_URL', nil)
    client_id = ENV.fetch('ONEHASH_CAL_CLIENT_ID', nil)
    redirect_uri = ENV.fetch('ONEHASH_CAL_OAUTH_REDIRECT_URL', nil)
    # scope = 'READ_BOOKING '
    scope = ''

    state = {
      team: 'disabled',
      account_user_id: Current.account_user.id
    }

    encoded_state = URI.encode_www_form_component(state.to_json)

    "#{oauth_provider_url}/auth/oauth2/authorize?client_id=#{client_id}&redirect_uri=#{redirect_uri}&scope=#{scope}&response_type=code&state=#{encoded_state}"
  end
end
