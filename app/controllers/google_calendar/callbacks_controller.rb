class GoogleCalendar::CallbacksController < ApplicationController
  include GoogleCalendar::IntegrationHelper

  def show
    return redirect_to(safe_redirect_uri) if params[:code].blank? || account_id.blank?

    tokens = Integrations::GoogleCalendar::Oauth.exchange_code(params[:code])
    persist_connection(tokens)
    redirect_to calendars_redirect_uri
  rescue StandardError => e
    Rails.logger.error("Google Calendar callback error: #{e.message}")
    redirect_to safe_redirect_uri
  end

  private

  def persist_connection(tokens)
    access_token = tokens['access_token']
    raise ArgumentError, 'Missing Google access token' if access_token.blank?

    profile = Integrations::GoogleCalendar::Oauth.fetch_profile(access_token)
    email = profile[:email]
    raise ArgumentError, 'Missing Google account email' if email.blank?

    connection = account.calendar_connections.find_or_initialize_by(provider: :google, email: email)
    refresh_token = tokens['refresh_token'].presence || connection.refresh_token
    raise ArgumentError, 'Missing Google refresh token' if refresh_token.blank?

    expires_in = tokens['expires_in'].to_i
    expires_in = 3600 if expires_in.zero?

    connection.assign_attributes(
      refresh_token: refresh_token,
      access_token: access_token,
      access_token_expires_at: Time.current.utc + expires_in.seconds,
      scopes: Array(tokens['scope'].to_s.split),
      is_active: true,
      connected_by: current_user,
      display_name: profile[:name].presence || Integrations::GoogleCalendar::Oauth.name_from_id_token(tokens['id_token'])
    )
    connection.save!
    @connection = connection
  end

  def account
    @account ||= Account.find(account_id)
  end

  def account_id
    return @account_id if instance_variable_defined?(:@account_id)

    @account_id = params[:state].present? ? verify_google_calendar_token(params[:state]) : nil
  end

  def calendars_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/calendars?setup=#{@connection.id}"
  end

  def safe_redirect_uri
    return base_url if account_id.blank?

    calendars_redirect_uri
  rescue StandardError
    base_url
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
