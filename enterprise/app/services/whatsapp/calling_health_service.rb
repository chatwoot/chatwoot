# Reports whether a calling-enabled WhatsApp Cloud inbox is set up at Meta to place and receive calls.
# Each check degrades to 'unverified' on its own, so one failing Meta request doesn't hide the others.
class Whatsapp::CallingHealthService
  UNVERIFIED = { status: 'unverified' }.freeze
  REQUEST_TIMEOUT_SECONDS = 15

  pattr_initialize [:channel!]

  def perform
    settings = calling_settings

    {
      meta_status: settings ? meta_status(settings) : UNVERIFIED,
      webhook_subscription: webhook_subscription,
      eligibility: settings ? eligibility(settings) : UNVERIFIED
    }
  end

  private

  def calling_settings
    channel.provider_service.calling_settings['calling'] || {}
  rescue StandardError => e
    log_failure('calling settings', e)
    nil
  end

  def meta_status(settings)
    { status: settings['status'] == 'ENABLED' ? 'enabled' : 'disabled' }
  end

  # Meta pauses calling for a week when users block or report calls; nothing on our side lifts it.
  def eligibility(settings)
    restrictions = settings.dig('restrictions', 'restrictions_list') || []

    {
      status: restrictions.any? ? 'restricted' : 'eligible',
      restrictions: restrictions.map do |restriction|
        { type: restriction['type'], expires_at: restriction['expiration'] && Time.zone.at(restriction['expiration']).iso8601 }
      end
    }
  end

  # Call webhooks need the app subscribed to the WABA (ours to fix by re-registering) and `calls` among
  # the app's own webhook fields, which only the Meta App Dashboard can change.
  def webhook_subscription
    app_id, app_secret = app_credentials
    return UNVERIFIED if app_id.blank? || app_secret.blank?
    return { status: 'missing', reason: 'app_not_subscribed' } unless app_subscribed_to_waba?(app_id)
    return { status: 'missing', reason: 'calls_field_missing' } unless calls_field_subscribed?(app_id, app_secret)

    { status: 'configured' }
  rescue StandardError => e
    log_failure('webhook subscription', e)
    UNVERIFIED
  end

  # Embedded signup tokens belong to the installation's app; manual setups bring their own app, whose secret is stored on the channel.
  def app_credentials
    if channel.provider_config['source'] == 'embedded_signup'
      return [GlobalConfigService.load('WHATSAPP_APP_ID', ''), GlobalConfigService.load('WHATSAPP_APP_SECRET', '')]
    end

    [graph_get('app', channel_token)['id'], channel.provider_config['app_secret']]
  end

  def app_subscribed_to_waba?(app_id)
    graph_get("#{channel.provider_config['business_account_id']}/subscribed_apps", channel_token).fetch('data', []).any? do |app|
      app.dig('whatsapp_business_api_data', 'id') == app_id
    end
  end

  # App-level webhook fields can only be read with an app access token.
  def calls_field_subscribed?(app_id, app_secret)
    subscriptions = graph_get("#{app_id}/subscriptions", "#{app_id}|#{app_secret}").fetch('data', [])
    waba_subscription = subscriptions.find { |subscription| subscription['object'] == 'whatsapp_business_account' && subscription['active'] }

    (waba_subscription&.fetch('fields', nil) || []).any? { |field| field['name'] == 'calls' }
  end

  def graph_get(path, token)
    version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
    response = HTTParty.get(
      "https://graph.facebook.com/#{version}/#{path}",
      headers: { 'Authorization' => "Bearer #{token}" }, timeout: REQUEST_TIMEOUT_SECONDS
    )
    raise "GET #{path} failed with status #{response.code}" unless response.success?

    response.parsed_response
  end

  def channel_token
    channel.provider_config['api_key']
  end

  def log_failure(check, error)
    Rails.logger.warn "[WHATSAPP CALL HEALTH] #{check} check failed: channel_id=#{channel.id} error=#{error.message}"
  end
end
