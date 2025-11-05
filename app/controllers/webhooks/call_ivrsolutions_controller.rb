require 'json'
require 'httparty'

# rubocop:disable Metrics/ClassLength
class Webhooks::CallIvrsolutionsController < ActionController::API
  include CallIvrsolutionsHelper
  include CommonCallHelper

  def handle_call_callback
    parsed_body = parse_request_body

    account = find_account(parsed_body)
    return render json: { error: 'Account not found' }, status: :not_found if account.blank?

    contact = find_contact(account, parsed_body)
    return render json: { error: 'Contact not found' }, status: :not_found if contact.blank?

    conversation = find_latest_conversation(contact, account)
    return render json: { error: 'Conversation not found' }, status: :not_found if conversation.blank?

    is_inbound = parsed_body['call_type'] == 'incoming'

    if is_inbound
      handle_incoming_callback(conversation, parsed_body, account)
    else
      create_call_log_message(conversation, parsed_body)
      send_call_log_to_bspd(parsed_body, conversation, account)

      head :ok
    end
  end

  def handle_missed_call_callback
    Rails.logger.info "IVR Solutions Missed call callback received: #{params.inspect}"

    parsed_body = parse_request_body
    Rails.logger.info "Parsed body: #{parsed_body.inspect}"

    account = find_account_by_id(parsed_body['account_id'])
    return render json: { error: 'Account not found' }, status: :not_found if account.blank?

    # Find or create contact based on the caller number
    contact = find_or_create_contact(account, parsed_body)

    # Find WA API inbox
    wa_api_inbox = find_wa_api_inbox(account)
    return render json: { error: 'WA Inbox not found' }, status: :bad_request if wa_api_inbox.blank?

    # Find latest conversation for the contact
    latest_conversation = find_latest_conversation(contact, account)

    conversation = handle_conversation_creation(latest_conversation, contact, wa_api_inbox)

    mark_conversation_as_inbound_call(conversation)

    # Determine the reason for missed call based on last_call_flow
    last_call_flow = parsed_body['last_call_flow']
    received_agent = parsed_body['received_agent']

    mark_conversation_as_missed_call_ivr(conversation, last_call_flow, received_agent)

    render json: { message: 'Missed call processed successfully' }, status: :ok
  end

  private

  def handle_incoming_callback(conversation, parsed_body, account) # rubocop:disable Metrics/AbcSize
    mark_conversation_as_inbound_call(conversation)

    agent_phone = parsed_body['attended_by']

    if agent_phone.blank?
      render json: { error: 'Agent phone number not found' }, status: :bad_request
      return
    end

    agent = account.users.find_by("custom_attributes->>'phone_number' LIKE ?", "%#{agent_phone.gsub(/^0/, '')}%")

    conversation.update!(assignee: agent)

    total_call_duration = parsed_body['call_duration'].to_i

    start_time = Time.parse(parsed_body['call_time']).in_time_zone('Asia/Kolkata').utc

    handled_call_duration = parsed_body['call_duration'].to_i

    add_handling_time_reporting_event(conversation, handled_call_duration, start_time) if handled_call_duration.positive?

    wait_time = total_call_duration - handled_call_duration

    add_waiting_time_reporting_event(conversation, wait_time, start_time) if wait_time.positive?

    call_log_message = get_inbound_call_log_string(parsed_body)

    conversation.messages.create!(private_message_params(call_log_message, conversation, parsed_body))

    send_call_log_to_bspd(parsed_body, conversation, account)

    head :ok
  end

  def parse_request_body
    JSON.parse(request.body.read)
  end

  def find_account(parsed_body)
    did_no = parsed_body['did_no'].gsub(/^\+/, '')
    Account.where("custom_attributes->>'call_config' IS NOT NULL")
           .find_by("custom_attributes->'call_config'->'externalProviderConfig'->>'did' = ?", did_no)
  end

  def find_contact(account, parsed_body)
    is_outgoing = parsed_body['call_type'] == 'outgoing'
    client_no = if is_outgoing
                  parsed_body['outgoing_ext'].gsub(/^0/, '+91')
                else
                  parsed_body['client_no'].gsub(/^0/, '+91')
                end
    Contact.find_by(account_id: account.id, phone_number: client_no)
  end

  def find_latest_conversation(contact, account)
    Conversation.where(
      contact_id: contact.id,
      account_id: account.id
    ).order(created_at: :desc).first
  end

  def create_call_log_message(conversation, parsed_body)
    call_log_message = get_call_log_string_ivr(parsed_body)
    conversation.messages.create!(private_message_params(call_log_message, conversation, parsed_body))
  end

  def private_message_params(content, conversation, parsed_body)
    time = Time.zone.parse(parsed_body['call_time'])
    new_time = time - ((5 * 3600) + (30 * 60))
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: content, private: true,
      content_attributes: { external_created_at: new_time.to_i }
    }
  end

  def send_call_log_to_bspd(parsed_body, conversation, account)
    Rails.logger.info "Sending call log to BSPD: #{parsed_body.inspect}"
    call_report = build_call_report_ivr_outbound(parsed_body, conversation, account)
    Rails.logger.info "Call log sent to BSPD: #{call_report.to_json}"
    send_report_to_bspd(call_report)
  rescue StandardError => e
    handle_error(e)
  end

  def send_report_to_bspd(call_report)
    response = HTTParty.post(
      'https://b3i4zxcefi.execute-api.us-east-1.amazonaws.com/chatwoot/webhook/callReport',
      body: call_report.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    handle_response(response)
  end

  def handle_response(response)
    unless response.success?
      Rails.logger.error "BSPD API returned error: #{response.body}"
      raise "BSPD API error: #{response.code} - #{response.body}"
    end
    Rails.logger.info "Call log sent to BSPD: #{response.body}"
  end

  def handle_error(error)
    Rails.logger.error "Error sending call log to BSPD: #{error.message}"
    raise error
  end

  def find_account_by_id(account_id)
    Account.find_by(id: account_id)
  end

  def find_or_create_contact(account, parsed_body)
    # Parse the caller number from the webhook
    caller_number = parsed_body['caller_number']

    # Normalize phone number to match existing format (+91...)
    normalized_number = caller_number.gsub(/^0/, '+91')
    normalized_number = "+91#{normalized_number}" unless normalized_number.start_with?('+')

    contact = Contact.find_by(account_id: account.id, phone_number: normalized_number)

    if contact.blank?
      contact = account.contacts.new(
        name: parsed_body['phone'],
        email: '',
        phone_number: normalized_number
      )
      contact.save!
    end

    contact
  end

  def find_wa_api_inbox(account)
    matching_inboxes = Inbox.where(account_id: account.id, channel_type: 'Channel::Api')
    matching_inboxes.find do |inbox|
      inbox.channel.additional_attributes['agent_reply_time_window'].present?
    end
  end

  def add_missed_call_label(conversation)
    Label.find_or_create_by!(
      account: conversation.account,
      title: 'missed-call'
    ) do |l|
      l.description = 'Automatically added to conversations with missed calls'
      l.show_on_sidebar = true
      l.color = '#7C21D7'
    end

    conversation.add_labels(['missed-call'])
  end

  def mark_conversation_as_missed_call_ivr(conversation, last_call_flow, received_agent) # rubocop:disable Metrics/MethodLength
    add_missed_call_label(conversation)

    reason = received_agent.blank? ? 'busy' : 'other'

    base_message = if reason == 'busy'
                     'Call was missed - No agents available'
                   else
                     'Call was missed'
                   end

    message = last_call_flow.present? ? "#{base_message}.\nLast Call Flow: #{last_call_flow}" : base_message

    conversation.messages.create!(private_message_params_for_missed_call(message, conversation))

    reporting_event_name = "conversation_missed_call_#{reason}"

    reporting_event = ReportingEvent.new(
      name: reporting_event_name,
      value: 1,
      value_in_business_hours: 1,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id || bot_user(conversation.account).id,
      conversation_id: conversation.id,
      event_start_time: conversation.updated_at,
      event_end_time: conversation.updated_at
    )

    reporting_event.save!
  end

  def private_message_params_for_missed_call(content, conversation)
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      private: true
    }
  end
end
# rubocop:enable Metrics/ClassLength
