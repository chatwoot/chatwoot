class Calendly::CallbacksController < ApplicationController
  include Calendly::IntegrationHelper

  def show
    token_data = Integrations::Calendly::ApiClient.exchange_code(params[:code], redirect_uri)
    setup_integration(token_data)
    redirect_to calendly_redirect_uri
  rescue StandardError => e
    Rails.logger.error("Calendly callback error: #{e.message}")
    redirect_to calendly_redirect_uri
  end

  private

  def setup_integration(token_data)
    api_client = build_temp_api_client(token_data)
    user_info = api_client.current_user
    signing_key = calendly_signing_key

    webhook = register_webhook(api_client, user_info, signing_key)
    create_hook(token_data, user_info, webhook, signing_key)
  rescue StandardError => e
    # Webhook registration may fail in dev (non-HTTPS URL).
    # Still create the hook so the integration is usable without webhooks.
    Rails.logger.warn("Calendly webhook registration failed: #{e.message}")
    create_hook(token_data, user_info, nil, signing_key)
  end

  def build_temp_api_client(token_data)
    temp_hook = Integrations::Hook.new(
      settings: build_token_settings(token_data).merge(
        'calendly_access_token' => token_data['access_token']
      )
    )
    Integrations::Calendly::ApiClient.new(temp_hook)
  end

  def register_webhook(api_client, user_info, signing_key)
    api_client.create_webhook_subscription(
      {
        url: "#{base_url}/webhooks/calendly",
        events: %w[invitee.created invitee.canceled],
        scope: 'user',
        organization_uri: user_info['current_organization'],
        user_uri: user_info['uri'],
        signing_key: signing_key
      }
    )
  end

  def create_hook(token_data, user_info, webhook, signing_key)
    destroy_existing_hook!
    account.hooks.create!(
      status: 'enabled',
      app_id: 'calendly',
      settings: build_token_settings(token_data).merge(
        'calendly_access_token' => token_data['access_token'],
        'calendly_user_uri' => user_info['uri'],
        'calendly_organization_uri' => user_info['current_organization'],
        'webhook_subscription_uri' => webhook&.dig('uri'),
        'signing_key' => signing_key
      )
    )
  end

  def destroy_existing_hook!
    existing = account.hooks.find_by(app_id: 'calendly')
    return unless existing

    existing.reauthorized!
    existing.destroy!
  end

  def build_token_settings(token_data)
    {
      'refresh_token' => token_data['refresh_token'],
      'token_expires_at' => token_data['expires_in'].seconds.from_now.iso8601
    }
  end

  def account
    @account ||= Account.find(account_id)
  end

  def account_id
    return unless params[:state]

    verify_calendly_token(params[:state])
  end

  def calendly_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/calendly"
  end

  def redirect_uri
    "#{base_url}/calendly/callback"
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def calendly_signing_key
    GlobalConfigService.load('CALENDLY_WEBHOOK_SIGNING_KEY', nil) || SecureRandom.hex(32)
  end
end
