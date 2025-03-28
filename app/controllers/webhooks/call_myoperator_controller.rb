require 'json'
require 'httparty'

class Webhooks::CallMyoperatorController < ActionController::API
  include CallIvrsolutionsHelper
  include CallMyoperatorHelper

  def handle_call_callback
    parsed_body = parse_request_body

    account = find_account(parsed_body)
    Rails.logger.info("account #{account.inspect}")
    return render json: { error: 'Account not found' }, status: :not_found if account.blank?

    contact = find_contact(account, parsed_body)
    Rails.logger.info("contact #{contact.inspect}")
    return render json: { error: 'Contact not found' }, status: :not_found if contact.blank?

    conversation = find_latest_conversation(contact, account)
    Rails.logger.info("conversation #{conversation.inspect}")
    return render json: { error: 'Conversation not found' }, status: :not_found if conversation.blank?

    is_inbound = parsed_body['event_log'] == 'incoming'

    if is_inbound
      handle_incoming_callback(conversation, parsed_body, account)
    else
      create_call_log_message(conversation, parsed_body)
      send_call_log_to_bspd(parsed_body, conversation, account)

      head :ok
    end
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

  def add_waiting_time_reporting_event(conversation, wait_time, start_time)
    reporting_event = ReportingEvent.new(
      name: 'conversation_call_waiting_time',
      value: wait_time,
      value_in_business_hours: wait_time,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id || bot_user(conversation.account).id,
      conversation_id: conversation.id,
      event_start_time: start_time,
      event_end_time: conversation.updated_at
    )

    reporting_event.save!
  end

  def add_handling_time_reporting_event(conversation, handled_time, start_time)
    reporting_event = ReportingEvent.new(
      name: 'conversation_call_handling_time',
      value: handled_time,
      value_in_business_hours: handled_time,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      user_id: conversation.assignee_id || bot_user(conversation.account).id,
      conversation_id: conversation.id,
      event_start_time: start_time,
      event_end_time: conversation.updated_at
    )

    reporting_event.save!
  end

  def mark_conversation_as_inbound_call(conversation)
    add_inbound_call_label(conversation)

    add_inbound_reporting_event(conversation)
  end

  def add_inbound_call_label(conversation)
    Label.find_or_create_by!(
      account: conversation.account,
      title: 'inbound-call'
    ) do |l|
      l.description = 'Automatically added to conversations with inbound calls'
      l.show_on_sidebar = true
      l.color = '#7C21D7' # Default color
    end

    conversation.add_labels(['inbound-call'])
  end

  def add_inbound_reporting_event(conversation)
    reporting_event = ReportingEvent.new(
      name: 'conversation_inbound_call',
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

  def parse_request_body
    request.query_parameters
  end

  def find_account(parsed_body)
    company_id = parsed_body['company_id']
    Account.where("custom_attributes->>'call_config' IS NOT NULL")
           .find_by("custom_attributes->'call_config'->'externalProviderConfig'->>'company_id' = ?", company_id)
  end

  def find_contact(account, parsed_body)
    client_no = parsed_body['phone_number'].gsub(/^0/, '+91')
    Rails.logger.info("client_no #{client_no}")
    Contact.find_by(account_id: account.id, phone_number: client_no)
  end

  def find_latest_conversation(contact, account)
    Conversation.where(
      contact_id: contact.id,
      account_id: account.id
    ).order(created_at: :desc).first
  end

  def create_call_log_message(conversation, parsed_body)
    call_log_message = get_call_log_string_my_operator(parsed_body)
    conversation.messages.create!(private_message_params(call_log_message, conversation, parsed_body))
  end

  def private_message_params(content, conversation, parsed_body)
    time = Time.at(parsed_body['call_start'].to_i).in_time_zone

    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      private: true,
      content_attributes: { external_created_at: time.to_i }
    }
  end

  def send_call_log_to_bspd(parsed_body, conversation, account)
    Rails.logger.info "Sending call log to BSPD: #{parsed_body.inspect}"
    call_report = build_call_report_myoperator(parsed_body, conversation, account)
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

  def bot_user(account)
    query = account.users.where('email LIKE ?', 'cx.%@bitespeed.co')
    query.first
  end
end
