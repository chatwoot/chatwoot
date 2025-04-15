class Crm::Leadsquared::SetupService
  REQUIRED_ACTIVITY_TYPES = [
    {
      name: 'Chatwoot Conversation Started',
      score: 10,
      direction: 0,
      setting_key: 'conversation_activity_code'
    },
    {
      name: 'Chatwoot Conversation Transcript',
      score: 5,
      direction: 0,
      setting_key: 'transcript_activity_code'
    }
  ].freeze

  def initialize(hook)
    @hook = hook
    credentials = @hook.settings

    @access_key = credentials['access_key']
    @secret_key = credentials['secret_key']
    @endpoint_url = credentials['endpoint_url']

    # Base client for activity type operations
    @client = Crm::Leadsquared::Api::BaseClient.new(@access_key, @secret_key, @endpoint_url)
    @activity_client = Crm::Leadsquared::Api::ActivityClient.new(@access_key, @secret_key, @endpoint_url)
  end

  def setup
    # Get existing activity types
    existing_types = fetch_activity_types
    return { success: false, error: existing_types[:error] } unless existing_types[:success]

    # Create any missing activity types
    setup_results = setup_activity_types(existing_types[:data])
    return setup_results unless setup_results[:success]

    # Update hook settings with activity type IDs
    update_hook_settings(setup_results[:activity_codes])

    # Return success with activity codes
    { success: true, activity_codes: setup_results[:activity_codes] }
  end

  private

  def fetch_activity_types
    path = '/ProspectActivity/Types'
    response = @client.get(path)

    if response[:success]
      { success: true, data: response[:data] }
    else
      Rails.logger.error "Failed to fetch LeadSquared activity types: #{response[:error]}"
      { success: false, error: response[:error] }
    end
  end

  def setup_activity_types(existing_types)
    activity_codes = {}
    success = true
    errors = []

    REQUIRED_ACTIVITY_TYPES.each do |activity_type|
      result = find_or_create_activity_type(activity_type, existing_types)

      if result[:success]
        activity_codes[activity_type[:setting_key]] = result[:activity_id]
      else
        success = false
        errors << result[:error]
      end
    end

    if success
      { success: true, activity_codes: activity_codes }
    else
      { success: false, errors: errors }
    end
  end

  def find_or_create_activity_type(activity_type, existing_types)
    # Check if activity type already exists
    existing = existing_types.find { |t| t['Name'] == activity_type[:name] }

    if existing
      # Use existing activity type
      activity_id = existing['Value'].to_i
      Rails.logger.info "Using existing LeadSquared activity type: #{activity_type[:name]} (ID: #{activity_id})"
      { success: true, activity_id: activity_id }
    else
      # Create new activity type
      result = @activity_client.create_activity_type(
        name: activity_type[:name],
        score: activity_type[:score],
        direction: activity_type[:direction]
      )

      if result[:success]
        Rails.logger.info "Created LeadSquared activity type: #{activity_type[:name]} (ID: #{result[:activity_id]})"
      else
        Rails.logger.error "Failed to create LeadSquared activity type: #{activity_type[:name]} - #{result[:error]}"
      end

      result
    end
  end

  def update_hook_settings(activity_codes)
    # Update hook settings with activity type IDs
    @hook.settings = @hook.settings.merge(activity_codes)
    @hook.save!
  end
end
