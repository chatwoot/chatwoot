class Tiendanube::CallbacksController < ApplicationController
  include Tiendanube::IntegrationHelper

  def show
    verify_account!

    @response = oauth_client.auth_code.get_token(
      params[:code],
      redirect_uri: '/tiendanube/callback'
    )

    handle_response
  rescue StandardError => e
    Rails.logger.error("Tiendanube callback error: #{e.message}")
    redirect_to "#{redirect_uri}?error=true"
  end

  private

  def verify_account!
    @account_id = verify_tiendanube_token(params[:state])
    raise StandardError, 'Invalid state parameter' if account.blank?
  end

  def handle_response
    account.hooks.create!(
      app_id: 'tiendanube',
      access_token: parsed_body['access_token'],
      status: 'enabled',
      reference_id: parsed_body['user_id'].to_s,
      settings: {
        scope: parsed_body['scope']
      }
    )

    redirect_to tiendanube_integration_url
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end

  def oauth_client
    OAuth2::Client.new(
      client_id,
      client_secret,
      {
        site: "https://#{params[:store_id]}.mitiendanube.com",
        authorize_url: '/apps/authorize/token',
        token_url: '/apps/authorize/token'
      }
    )
  end

  def account
    @account ||= Account.find(@account_id)
  end

  def account_id
    @account_id ||= params[:state].split('_').first
  end

  def tiendanube_integration_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/tiendanube"
  end

  def redirect_uri
    return tiendanube_integration_url if account

    ENV.fetch('FRONTEND_URL', nil)
  end
end
