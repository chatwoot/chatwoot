class Pathors::CallbacksController < ApplicationController
  include Pathors::IntegrationHelper

  # OAuth callback for the Pathors connect flow (fork feature).
  #
  # By the time the browser lands here, the heavy lifting already happened on
  # the Pathors side: the consent page provisioned the agent bot into this
  # account before issuing the code. This controller's job is only to redeem
  # the code for tokens and file them in an integration hook, so the dashboard
  # can later call Pathors APIs on the account's behalf.
  #
  # The account comes from the signed `state` token this fork minted when the
  # connect started — same pattern as Linear's callback, same reason: there is
  # no session context on this redirect.
  def show
    return redirect_to(safe_pathors_redirect_uri) if params[:code].blank? || account_id.blank?

    @response = oauth_client.auth_code.get_token(
      params[:code],
      redirect_uri: Integrations::App.pathors_integration_url
    )

    handle_response
  rescue StandardError => e
    Rails.logger.error("Pathors callback error: #{e.message}")
    redirect_to safe_pathors_redirect_uri
  end

  private

  def oauth_client
    client_id = GlobalConfigService.load('PATHORS_OAUTH_CLIENT_ID', nil)
    client_secret = GlobalConfigService.load('PATHORS_OAUTH_CLIENT_SECRET', nil)

    OAuth2::Client.new(
      client_id,
      client_secret,
      {
        site: GlobalConfigService.load('PATHORS_API_URL', 'https://api.pathors.com'),
        token_url: '/oauth/token'
      }
    )
  end

  def handle_response
    raise ArgumentError, 'Missing access token in Pathors OAuth response' if parsed_body['access_token'].blank?

    hook = account.hooks.find_or_initialize_by(app_id: 'pathors')
    hook.assign_attributes(
      access_token: parsed_body['access_token'],
      status: 'enabled',
      settings: merged_integration_settings(hook.settings)
    )
    hook.save!
    redirect_to pathors_redirect_uri
  rescue StandardError => e
    Rails.logger.error("Pathors callback error: #{e.message}")
    redirect_to safe_pathors_redirect_uri
  end

  def account
    @account ||= Account.find(account_id)
  end

  def account_id
    return @account_id if instance_variable_defined?(:@account_id)

    @account_id = params[:state].present? ? verify_pathors_token(params[:state]) : nil
  end

  def pathors_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/pathors"
  end

  def safe_pathors_redirect_uri
    return base_url if account_id.blank?

    pathors_redirect_uri
  rescue StandardError
    base_url
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end

  def integration_settings
    {
      token_type: parsed_body['token_type'],
      expires_in: parsed_body['expires_in'],
      expires_on: expires_on,
      scope: parsed_body['scope'],
      refresh_token: parsed_body['refresh_token'],
      # Which Pathors tenant this account was bound to at consent time. Consent
      # now binds a whole organization; connections made before that carry a
      # project instead, so whichever the response sends is what gets filed.
      organization_id: parsed_body['organization_id'],
      project_id: parsed_body['project_id']
    }.compact
  end

  def merged_integration_settings(existing_settings)
    existing_settings.to_h.with_indifferent_access.merge(integration_settings)
  end

  def expires_on
    return if parsed_body['expires_in'].blank?

    (Time.current.utc + parsed_body['expires_in'].to_i.seconds).to_s
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
