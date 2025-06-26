class Crm::Leadsquared::SetupService
  def initialize(hook)
    @hook = hook
    credentials = @hook.settings

    @access_key = credentials['access_key']
    @secret_key = credentials['secret_key']

    @client = Crm::Leadsquared::Api::BaseClient.new(@access_key, @secret_key, 'https://api.leadsquared.com/v2/')
    @activity_client = Crm::Leadsquared::Api::ActivityClient.new(@access_key, @secret_key, 'https://api.leadsquared.com/v2/')
  end

  def setup
    setup_endpoint
    setup_activity
  rescue Crm::Leadsquared::Api::BaseClient::ApiError => e
    ChatwootExceptionTracker.new(e, account: @hook.account).capture_exception
    Rails.logger.error "LeadSquared API error in setup: #{e.message}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @hook.account).capture_exception
    Rails.logger.error "Error during LeadSquared setup: #{e.message}"
  end

  def setup_endpoint
    response = @client.get('Authentication.svc/UserByAccessKey.Get')
    endpoint_host = response['LSQCommonServiceURLs']['api']
    app_host = response['LSQCommonServiceURLs']['app']
    timezone = response['TimeZone']

    endpoint_url = "https://#{endpoint_host}/v2/"
    app_url = "https://#{app_host}/"

    update_hook_settings({ :endpoint_url => endpoint_url, :app_url => app_url, :timezone => timezone })

    # replace the clients
    @client = Crm::Leadsquared::Api::BaseClient.new(@access_key, @secret_key, endpoint_url)
    @activity_client = Crm::Leadsquared::Api::ActivityClient.new(@access_key, @secret_key, endpoint_url)
  end

  private

  def setup_activity
    existing_types = @activity_client.fetch_activity_types
    return if existing_types.blank?

    activity_codes = setup_activity_types(existing_types)
    return if activity_codes.blank?

    update_hook_settings(activity_codes)

    activity_codes
  end

  def setup_activity_types(existing_types)
    activity_codes = {}

    activity_types.each do |activity_type|
      activity_id = find_or_create_activity_type(activity_type, existing_types)

      if activity_id.present?
        activity_codes[activity_type[:setting_key]] = activity_id.to_i
      else
        Rails.logger.error "Failed to find or create activity type: #{activity_type[:name]}"
      end
    end

    activity_codes
  end

  def find_or_create_activity_type(activity_type, existing_types)
    existing = existing_types.find { |t| t['ActivityEventName'] == activity_type[:name] }

    if existing
      existing['ActivityEvent'].to_i
    else
      @activity_client.create_activity_type(
        name: activity_type[:name],
        score: activity_type[:score],
        direction: activity_type[:direction]
      )
    end
  end

  def update_hook_settings(params)
    @hook.settings = @hook.settings.merge(params)
    @hook.save!
  end

  def activity_types
    [
      {
        name: "#{brand_name} Conversation Started",
        score: @hook.settings['conversation_activity_score'].to_i || 0,
        direction: 0,
        setting_key: 'conversation_activity_code'
      },
      {
        name: "#{brand_name} Conversation Transcript",
        score: @hook.settings['transcript_activity_score'].to_i || 0,
        direction: 0,
        setting_key: 'transcript_activity_code'
      }
    ].freeze
  end

  def brand_name
    ::GlobalConfig.get('BRAND_NAME')['BRAND_NAME'].presence || 'Chatwoot'
  end
end
