class Integrations::Calendly::ApiClient
  BASE_URL = 'https://api.calendly.com'.freeze
  AUTH_URL = 'https://auth.calendly.com'.freeze
  MAX_RETRIES = 3

  def initialize(hook)
    @hook = hook
  end

  def current_user
    response = request(:get, '/users/me')
    response['resource']
  end

  def list_event_types(user_uri: nil, active: true)
    user_uri ||= @hook.settings['calendly_user_uri']
    response = request(:get, '/event_types', params: { user: user_uri, active: active })
    response['collection'] || []
  end

  def get_event_type(uuid)
    response = request(:get, "/event_types/#{uuid}")
    response['resource']
  end

  def list_available_times(event_type_uri, start_time:, end_time:)
    params = { event_type: event_type_uri, start_time: start_time.iso8601, end_time: end_time.iso8601 }
    response = request(:get, '/event_type_available_times', params: params)
    response['collection'] || []
  end

  def create_scheduling_link(event_type_uri, max_event_count: 1)
    body = { max_event_count: max_event_count, owner: event_type_uri, owner_type: 'EventType' }
    response = request(:post, '/scheduling_links', body: body)
    response['resource']
  end

  def list_scheduled_events(user_uri: nil, min_start_time: nil, max_start_time: nil, status: 'active')
    user_uri ||= @hook.settings['calendly_user_uri']
    params = build_events_params(user_uri, min_start_time, max_start_time, status)
    response = request(:get, '/scheduled_events', params: params)
    response['collection'] || []
  end

  def get_scheduled_event(uuid)
    response = request(:get, "/scheduled_events/#{uuid}")
    response['resource']
  end

  def cancel_event(uuid, reason: nil)
    request(:post, "/scheduled_events/#{uuid}/cancellation", body: { reason: reason }.compact)
  end

  def list_invitees(event_uuid)
    response = request(:get, "/scheduled_events/#{event_uuid}/invitees")
    response['collection'] || []
  end

  def create_webhook_subscription(params)
    body = {
      url: params[:url], events: params[:events], organization: params[:organization_uri],
      scope: params[:scope], signing_key: params[:signing_key]
    }
    body[:user] = params[:user_uri] if params[:user_uri]
    response = request(:post, '/webhook_subscriptions', body: body)
    response['resource']
  end

  def delete_webhook_subscription(uuid)
    request(:delete, "/webhook_subscriptions/#{uuid}")
  end

  def self.exchange_code(code, redirect_uri)
    client_id = GlobalConfigService.load('CALENDLY_CLIENT_ID', nil)
    client_secret = GlobalConfigService.load('CALENDLY_CLIENT_SECRET', nil)

    response = HTTParty.post(
      "#{AUTH_URL}/oauth/token",
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
      body: { grant_type: 'authorization_code', client_id: client_id, client_secret: client_secret, code: code,
              redirect_uri: redirect_uri }
    )
    raise "Calendly OAuth error: #{response.body}" unless response.success?

    response.parsed_response
  end

  private

  def access_token
    refresh_token_if_expired!
    @hook.settings['calendly_access_token']
  end

  def refresh_token_if_expired!
    expires_at = @hook.settings['token_expires_at']
    return if expires_at.blank?
    return if Time.zone.parse(expires_at) > 5.minutes.from_now

    perform_token_refresh!
  end

  def perform_token_refresh!
    data = request_new_token
    update_hook_tokens(data)
  end

  def request_new_token
    client_id = GlobalConfigService.load('CALENDLY_CLIENT_ID', nil)
    client_secret = GlobalConfigService.load('CALENDLY_CLIENT_SECRET', nil)

    response = HTTParty.post(
      "#{AUTH_URL}/oauth/token",
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
      body: { grant_type: 'refresh_token', client_id: client_id, client_secret: client_secret,
              refresh_token: @hook.settings['refresh_token'] }
    )

    unless response.success?
      @hook.authorization_error!
      raise "Calendly token refresh failed: #{response.body}"
    end

    response.parsed_response
  end

  def update_hook_tokens(data)
    @hook.update!(
      settings: @hook.settings.merge(
        'calendly_access_token' => data['access_token'],
        'refresh_token' => data['refresh_token'],
        'token_expires_at' => data['expires_in'].seconds.from_now.iso8601
      )
    )
  end

  def build_events_params(user_uri, min_start_time, max_start_time, status)
    params = { user: user_uri, status: status }.compact
    params[:min_start_time] = min_start_time.iso8601 if min_start_time
    params[:max_start_time] = max_start_time.iso8601 if max_start_time
    params
  end

  def request(method, path, body: nil, params: nil)
    retries = 0
    begin
      response = HTTParty.public_send(method, "#{BASE_URL}#{path}", headers: request_headers, body: body&.to_json, query: params)
      handle_response(response)
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      retries += 1
      retry if retries < MAX_RETRIES
      raise e
    end
  end

  def handle_response(response)
    case response.code
    when 200..299
      return {} if response.body.blank?

      response.parsed_response
    when 401
      @hook.authorization_error!
      raise "Calendly API unauthorized: #{response.body}"
    when 429
      raise "Calendly API rate limited. Retry after #{response.headers['Retry-After']&.to_i || 60}s"
    else
      raise "Calendly API error (#{response.code}): #{response.body}"
    end
  end

  def request_headers
    { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' }
  end
end
