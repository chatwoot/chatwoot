require 'httparty'
require 'json'
require 'rexml/document'

class Api::V1::Accounts::CallV2Controller < Api::V1::Accounts::BaseController # rubocop:disable Metrics/ClassLength
  include CommonCallHelper

  def create # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    account = Account.find_by(id: params[:account_id])

    call_config = account&.custom_attributes&.[]('call_config')

    if call_config.blank?
      render json: { success: false, error: 'Call config not found!' }, status: :bad_request
      return
    end

    payload = begin
      JSON.parse(request.body.read)
    rescue StandardError
      {}
    end

    conversation = handle_get_or_create_conversation(account)

    Rails.logger.info("conversationData, #{conversation.inspect}")

    provider = call_config['externalProvider']

    response = case provider
               when 'exotel'
                 handle_exotel_provider_call(call_config, payload, conversation)
               when 'ivrsolutions'
                 handle_ivrsolutions_provider_call(call_config, payload)
               when 'myoperator'
                 handle_myoperator_provider_call(call_config, payload)
               when 'ozonetel'
                 handle_ozonetel_provider_call(call_config, payload)
               else
                 render json: { success: false, error: 'Invalid provider configuration' }, status: :bad_request
                 return
               end

    if response.code != 200
      error_message = extract_error_message(response, provider)
      render json: { success: false, response: error_message }
      conversation.messages.create!(private_message_params_error("Error in initiating call: #{error_message}", conversation))
      return
    end

    case provider
    when 'exotel'
      create_follow_up_call_reporting_event(conversation)
    when 'ivrsolutions', 'myoperator', 'ozonetel'
      conversation.messages.create!(private_message_params('Call Initiated', conversation))
      create_follow_up_call_reporting_event(conversation)
    end
    render json: { success: true, response: response.body }
  end

  def update_call_config
    account = Account.find_by(id: params[:account_id])
    payload = begin
      JSON.parse(request.body.read)
    rescue StandardError
      {}
    end

    custom_attributes = account.custom_attributes || {}

    updated_custom_attributes = custom_attributes.merge('call_config' => payload['call_config'])

    account.update(custom_attributes: updated_custom_attributes)

    render json: { success: true, message: 'Call config updated successfully' }
  end

  def handle_get_or_create_conversation(account) # rubocop:disable Metrics/AbcSize
    matching_inboxes = Inbox.where(account_id: account.id, channel_type: 'Channel::Api')
    Rails.logger.info("matching_inboxes Data, #{matching_inboxes.inspect}")
    wa_api_inbox = matching_inboxes.find do |inbox|
      inbox.channel.additional_attributes['agent_reply_time_window'].present?
    end

    Rails.logger.info("Wa_api_inbox, #{wa_api_inbox.inspect}")

    if wa_api_inbox.blank?
      render json: { error: 'WA Inbox not found' }, status: :bad_request
      return
    end

    contact = Contact.find_by(id: params[:contactId])

    Rails.logger.info("contact, #{contact.inspect}")

    # Find latest conversation for the contact
    latest_conversation = Conversation.where(
      contact_id: contact.id,
      account_id: account.id
    ).order(created_at: :desc).first

    Rails.logger.info("latest_conversation, #{latest_conversation.inspect}")

    handle_conversation_creation(latest_conversation, contact, wa_api_inbox)
  end

  def private_message_params_error(error, conversation)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :outgoing, content: '', private: true,
      additional_attributes: { type: 'error', content: error } }
  end

  def private_message_params(content, conversation)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :outgoing, content: content, private: true }
  end

  def create_follow_up_call_reporting_event(conversation)
    Rails.logger.info('CREATE FOLLOW-UP CALL REPORTING EVENT')
    Rails.logger.info("conversation.custom_attributes['calling_status'].present? #{conversation.custom_attributes['calling_status'].present?}")
    Rails.logger.info("conversation.custom_attributes['calling_status'] == 'Follow-up' #{conversation.custom_attributes['calling_status']}")
    return unless conversation.custom_attributes['calling_status'].present? &&
                  conversation.custom_attributes['calling_status'] == 'Follow-up'

    reporting_event = ReportingEvent.new(
      name: 'conversation_follow_up_call',
      value: 1,
      value_in_business_hours: 1,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id,
      conversation_id: conversation.id,
      event_start_time: conversation.updated_at,
      event_end_time: conversation.updated_at
    )

    reporting_event.save!
  end

  def handle_exotel_provider_call(call_config, payload, latest_open_conversation) # rubocop:disable Metrics/MethodLength
    external_provider_config = call_config['externalProviderConfig']

    display_id = latest_open_conversation.display_id
    inbox_id = latest_open_conversation.inbox_id

    status_callback = "#{payload['baseUrl']}/webhooks/call/#{params[:account_id]}/#{inbox_id}/#{display_id}"

    unless payload['to'] && payload['from']
      render json: { success: false, error: 'Missing required fields: to or from' }, status: :bad_request
      return
    end

    url = "https://#{external_provider_config['apiKey']}:#{external_provider_config['token']}#{external_provider_config['subDomain']}/v1/Accounts/#{external_provider_config['sid']}/Calls/connect"

    form_data = {
      To: payload['to'],
      From: payload['from'],
      CallerId: external_provider_config['callerId'],
      StatusCallback: status_callback,
      'StatusCallbackEvents[0]': 'terminal',
      'StatusCallbackEvents[1]': 'answered',
      StatusCallbackContentType: 'application/json',
      Record: true
    }

    HTTParty.post(
      url,
      basic_auth: { username: external_provider_config['apiKey'], password: external_provider_config['token'] },
      body: form_data
    )
  end

  def handle_ivrsolutions_provider_call(call_config, payload) # rubocop:disable Metrics/MethodLength
    external_provider_config = call_config['externalProviderConfig']
    unless payload['to'] && payload['from']
      render json: { success: false, error: 'Missing required fields: to or from' }, status: :bad_request
      return
    end

    ext_no = external_provider_config['extNoMapping'][payload['from'].gsub(/^\+91/, '')]

    unless ext_no
      Rails.logger.error("No extension mapping found for number: #{payload['from']}")
      return { success: false, error: "No extension mapping found for number: #{payload['from']}" }
    end

    formatted_to_number = payload['to'].gsub(/^\+91/, '')

    # IVR Solutions API endpoint
    url = 'https://api.ivrsolutions.in/api/c2c_get'

    # Prepare query parameters
    query_params = {
      token: external_provider_config['token'],
      did: external_provider_config['did'],
      ext_no: ext_no,
      phone: formatted_to_number
    }

    HTTParty.get(
      url,
      query: query_params,
      headers: {
        'Content-Type': 'application/json'
      }
    )
  end

  def handle_myoperator_provider_call(call_config, payload) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    Rails.logger.info('Inside My Operator')
    external_provider_config = call_config['externalProviderConfig']

    unless payload['to'] && payload['from']
      render json: { success: false, error: 'Missing required fields: to or from' }, status: :bad_request
      return
    end

    user_id = external_provider_config['agentNoMapping'][payload['from'].gsub(/^\+91/, '')]

    Rails.logger.info("user_id #{user_id}")

    unless user_id
      Rails.logger.error("No userid found for number: #{payload['from']}")
      return { success: false, error: "No userid found for number: #{payload['from']}" }
    end

    Rails.logger.info("formatted_to_number #{payload['to']}")

    url = 'https://obd-api.myoperator.co/obd-api-v1'

    params = {
      company_id: external_provider_config['company_id'],
      secret_token: external_provider_config['secret_token'],
      type: '1',
      user_id: user_id,
      number: payload['to'],
      public_ivr_id: external_provider_config['public_ivr_id']
    }

    Rails.logger.info("params, #{params.to_json.inspect}")

    HTTParty.post(
      url,
      body: params.to_json,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': external_provider_config['x_api_key']
      }
    )
  end

  def handle_ozonetel_provider_call(call_config, payload) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    Rails.logger.info('Inside ozonetel')
    external_provider_config = call_config['externalProviderConfig']

    unless payload['to'] && payload['from']
      render json: { success: false, error: 'Missing required fields: to or from' }, status: :bad_request
      return
    end

    campaign_name = call_config['externalProviderConfig']['outboundCampaignName']

    phone_name = external_provider_config['agentNoMapping'][payload['from'].gsub(/^\+91/, '')]

    Rails.logger.info("phone_name #{phone_name}")

    unless phone_name
      Rails.logger.error("No phone_name found for number: #{payload['from']}")
      return { success: false, error: "No phone_name found for number: #{payload['from']}" }
    end

    Rails.logger.info("formatted_to_number #{payload['to']}")

    url = 'https://in1-ccaas-api.ozonetel.com/ca_apis/AgentManualDial'

    params = {
      userName: external_provider_config['userName'],
      customerNumber: payload['to'],
      agentID: phone_name,
      campaignName: campaign_name
    }

    Rails.logger.info("params, #{params.to_json.inspect}")

    HTTParty.post(
      url,
      body: params.to_json,
      headers: {
        'Content-Type': 'application/json',
        'apiKey': external_provider_config['apiKey']
      }
    )
  end

  def extract_error_message(response, provider)
    case provider
    when 'exotel'
      xml_data = REXML::Document.new(response.body)
      xml_data.elements['//Message']&.text || 'Unknown error'
    when 'ivrsolutions', 'myoperator', 'ozonetel'
      begin
        result = JSON.parse(response.body)
        result['message'] || 'Unknown error'
      rescue JSON::ParserError => e
        "Failed to parse response: #{e.message}"
      end
    else
      'Unknown error'
    end
  end
end
