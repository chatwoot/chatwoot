class Zalo::CallbackController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def create
    code = params[:code]
    oa_id = params[:oa_id]
    account_id = params[:state]

    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    secret_key = ENV.fetch('ZALO_APP_SECRET', nil)
    app_id = ENV.fetch('ZALO_APP_ID', nil)

    payload = build_payload(code, app_id)

    response = request_access_token(secret_key, payload)

    if response.code == 200
      channel = save_channel(response, oa_id, account_id)
      redirect_to "#{frontend_url}/app/accounts/#{account_id}/settings/inboxes/new/zalo?channel_id=#{channel.id}"
    else
      error_message = response.parsed_response['message']
      redirect_to "#{frontend_url}/app/accounts/#{account_id}/settings/inboxes/new/zalo?error_message=#{error_message}"
    end
  end

  private

  def build_payload(code, app_id)
    {
      code: code,
      app_id: app_id,
      grant_type: 'authorization_code'
    }
  end

  def request_access_token(secret_key, payload)
    HTTParty.post(
      'https://oauth.zaloapp.com/v4/oa/access_token',
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded', 'secret_key' => secret_key },
      body: URI.encode_www_form(payload)
    )
  end

  def save_channel(response, oa_id, account_id)
    oa_access_token = response.parsed_response['access_token']
    refresh_token = response.parsed_response['refresh_token']
    expires_in = response.parsed_response['expires_in']
    Channel::ZaloOA.create(
      oa_access_token: oa_access_token,
      refresh_token: refresh_token,
      expires_in: expires_in,
      oa_id: oa_id,
      account_id: account_id
    )
  end
end
