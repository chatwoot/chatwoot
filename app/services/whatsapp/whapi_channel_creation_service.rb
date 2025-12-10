# frozen_string_literal: true

class Whatsapp::WhapiChannelCreationService
  def initialize(account:, phone_number:, inbox_name:)
    @account = account
    @phone_number = phone_number
    @inbox_name = inbox_name
  end

  def perform
    Rails.logger.info "[WHATSAPP_LIGHT] Starting channel creation for phone: #{@phone_number}"
    validate_parameters!

    existing_channel = find_existing_channel
    if existing_channel
      Rails.logger.error "[WHATSAPP_LIGHT] Channel already exists for phone number: #{@phone_number}"
      raise "Channel already exists for phone number: #{@phone_number}"
    end

    Rails.logger.info "[WHATSAPP_LIGHT] Creating channel in Whapi.cloud"
    channel_data = create_whapi_channel
    Rails.logger.info "[WHATSAPP_LIGHT] Whapi channel created successfully. ID: #{channel_data['id']}"

    result = create_channel_with_inbox(channel_data)
    Rails.logger.info "[WHATSAPP_LIGHT] Channel and Inbox created successfully. Inbox ID: #{result[:inbox].id}"
    result
  end

  private

  def validate_parameters!
    raise ArgumentError, 'Account is required' if @account.blank?
    raise ArgumentError, 'Phone number is required' if @phone_number.blank?
    raise ArgumentError, 'Inbox name is required' if @inbox_name.blank?
    raise ArgumentError, 'WHAPI_BEARER_TOKEN not configured' if bearer_token.blank?
    raise ArgumentError, 'WHAPI_PROJECT_ID not configured' if project_id.blank?
  end

  def find_existing_channel
    Channel::Whatsapp.find_by(
      account: @account,
      phone_number: formatted_phone_number
    )
  end

  def create_whapi_channel
    url = "#{manager_url}/channels"
    Rails.logger.info "[WHATSAPP_LIGHT] Making PUT request to: #{url}"

    response = HTTParty.put(
      url,
      headers: {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{bearer_token}"
      },
      body: {
        name: @inbox_name,
        phone: phone_number_for_whapi,
        projectId: project_id
      }.to_json
    )

    Rails.logger.info "[WHATSAPP_LIGHT] Whapi response status: #{response.code}"

    unless response.success?
      error_message = response.parsed_response&.dig('message') || 'Failed to create channel in Whapi'
      Rails.logger.error "[WHATSAPP_LIGHT] Whapi channel creation failed: #{error_message}"
      Rails.logger.error "[WHATSAPP_LIGHT] Response body: #{response.body}"
      raise "Whapi channel creation failed: #{error_message}"
    end

    response.parsed_response
  end

  def create_channel_with_inbox(channel_data)
    ActiveRecord::Base.transaction do
      channel = build_channel(channel_data)
      inbox = create_inbox(channel)
      { channel: channel, inbox: inbox, channel_data: channel_data }
    end
  end

  def build_channel(channel_data)
    Channel::Whatsapp.create!(
      account: @account,
      phone_number: formatted_phone_number,
      provider: 'whatsapp_light',
      provider_config: {
        channel_id: channel_data['id'],
        token: channel_data['token'],
        api_url: channel_data['apiUrl'],
        phone: channel_data['phone'],
        project_id: channel_data['projectId'],
        server: channel_data['server'],
        status: channel_data['status'],
        mode: channel_data['mode'],
        created_at: Time.zone.now.iso8601
      }
    )
  end

  def create_inbox(channel)
    Inbox.create!(
      account: @account,
      name: @inbox_name,
      channel: channel
    )
  end

  def formatted_phone_number
    # Ensure phone number has + prefix
    number = @phone_number.strip
    number.start_with?('+') ? number : "+#{number}"
  end

  def phone_number_for_whapi
    # Whapi expects phone number without + prefix, only digits
    @phone_number.gsub(/[^\d]/, '')
  end

  def bearer_token
    ENV.fetch('WHAPI_BEARER_TOKEN', nil)
  end

  def project_id
    ENV.fetch('WHAPI_PROJECT_ID', nil)
  end

  def manager_url
    ENV.fetch('WHAPI_MANAGER_URL', 'https://manager.whapi.cloud')
  end
end
