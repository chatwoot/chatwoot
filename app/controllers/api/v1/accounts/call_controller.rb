require 'httparty'
require 'json'
require 'rexml/document'

class Api::V1::Accounts::CallController < Api::V1::Accounts::BaseController
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def create
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

    latest_open_conversation = Conversation.where(
      contact_id: params[:contactId],
      account_id: params[:account_id]
    ).order(created_at: :desc).first

    if latest_open_conversation.blank?
      Rails.logger.info("No conversation found for contact #{params[:contactId]}")
      render json: { success: false, error: 'No open conversation found for contact' }, status: :bad_request
      return
    end

    if latest_open_conversation.status != 'open'
      Rails.logger.info("Conversation #{latest_open_conversation.id} is not open")
      latest_open_conversation.update(status: 'open')
      latest_open_conversation.save!
    end

    # determine display_id, inbox_id
    display_id = latest_open_conversation.display_id
    inbox_id = latest_open_conversation.inbox_id

    status_callback = "#{payload['baseUrl']}/webhooks/call/#{params[:account_id]}/#{inbox_id}/#{display_id}"

    unless payload['to'] && payload['from']
      render json: { success: false, error: 'Missing required fields: to or from' }, status: :bad_request
      return
    end

    url = "https://#{call_config['apiKey']}:#{call_config['token']}#{call_config['subDomain']}/v1/Accounts/#{call_config['sid']}/Calls/connect"

    form_data = {
      To: payload['to'],
      From: payload['from'],
      CallerId: call_config['callerId'],
      StatusCallback: status_callback,
      'StatusCallbackEvents[0]': 'terminal',
      'StatusCallbackEvents[1]': 'answered',
      StatusCallbackContentType: 'application/json',
      Record: true
    }

    response = HTTParty.post(
      url,
      basic_auth: { username: call_config['apiKey'], password: call_config['token'] },
      body: form_data
    )

    conversation = latest_open_conversation

    if response.code != 200
      xml_data = REXML::Document.new(response.body)
      error_message = xml_data.elements['//Message'].text
      render json: { success: false, response: error_message }
      conversation.messages.create!(private_message_params("Error in iniating call: #{error_message}", conversation))
      return
    end
    create_follow_up_call_reporting_event(conversation)
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

  def private_message_params(error, conversation)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :outgoing, content: '', private: true,
      additional_attributes: { type: 'error', content: error } }
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
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
