require 'json'
require 'httparty'

class Webhooks::CallMyoperatorController < ActionController::API
  include CallMyoperatorHelper
  include CommonCallHelper

  def handle_call_callback
    parsed_body = parse_request_body

    account = find_account(parsed_body)
    Rails.logger.info("account #{account.inspect}")
    return render json: { error: 'Account not found' }, status: :not_found if account.blank?

    is_inbound = parsed_body['event_log'] == 'incoming'

    contact = find_contact_or_create_contact(account, parsed_body, is_inbound)
    Rails.logger.info("contact #{contact.inspect}")

    if is_inbound
      handle_incoming_call(account, contact, parsed_body)
    else
      return render json: { error: 'Contact not found' }, status: :not_found if contact.blank?

      conversation = find_latest_conversation(contact, account)
      Rails.logger.info("conversation #{conversation.inspect}")
      return render json: { error: 'Conversation not found' }, status: :not_found if conversation.blank?

      create_call_log_message(conversation, parsed_body)
      send_call_log_to_bspd(parsed_body, conversation, account)

      head :ok
    end
  end

  private

  def handle_incoming_call(account, contact, parsed_body)
    matching_inboxes = Inbox.where(account_id: account.id, channel_type: 'Channel::Api')
    Rails.logger.info("matching_inboxes Data, #{matching_inboxes.inspect}")
    wa_api_inbox = matching_inboxes.find do |inbox|
      inbox.channel.additional_attributes['agent_reply_time_window'].present?
    end

    if wa_api_inbox.blank?
      render json: { error: 'WA Inbox not found' }, status: :bad_request
      return
    end

    # Find latest conversation for the contact
    latest_conversation = Conversation.where(
      contact_id: contact.id,
      account_id: account.id
    ).order(created_at: :desc).first

    conversation = handle_conversation_creation(latest_conversation, contact, wa_api_inbox)
    handle_incoming_callback(conversation, parsed_body, account)
  end

  def handle_incoming_callback(conversation, parsed_body, account) # rubocop:disable Metrics/AbcSize
    mark_conversation_as_inbound_call(conversation)

    agent_phone = parsed_body['agent_number']

    if agent_phone.present?
      agent = account.users.find_by("custom_attributes->>'phone_number' LIKE ?", "%#{agent_phone.gsub(/^0/, '')}%")
      conversation.update!(assignee: agent)
    end

    total_call_duration = convert_duration_to_seconds(parsed_body['call_duration'])

    start_time = Time.at(parsed_body['call_start'].to_i).in_time_zone('Asia/Kolkata').utc

    handled_call_duration = convert_duration_to_seconds(parsed_body['call_duration'])

    add_handling_time_reporting_event(conversation, handled_call_duration, start_time) if handled_call_duration.positive?

    wait_time = total_call_duration - handled_call_duration

    add_waiting_time_reporting_event(conversation, wait_time, start_time) if wait_time.positive?

    call_log_message = get_call_log_string_my_operator(parsed_body)

    conversation.messages.create!(private_message_params(call_log_message, conversation, parsed_body))

    send_call_log_to_bspd(parsed_body, conversation, account)

    head :ok
  end

  def parse_request_body
    request.query_parameters
  end

  def find_account(parsed_body)
    company_id = parsed_body['company_id']
    Account.where("custom_attributes->>'call_config' IS NOT NULL")
           .find_by("custom_attributes->'call_config'->'externalProviderConfig'->>'company_id' = ?", company_id)
  end

  def find_contact_or_create_contact(account, parsed_body, is_inbound)
    client_no = parsed_body['phone_number'].gsub(/^0/, '+91')
    Rails.logger.info("client_no #{client_no}")

    contact = Contact.find_by(account_id: account.id, phone_number: client_no)

    if is_inbound && contact.blank?
      contact = account.contacts.create!(
        name: parsed_body['phone_number'],
        email: '',
        phone_number: client_no
      )
      contact.save!
    end

    contact
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

  def handle_error(error)
    Rails.logger.error "Error sending call log to BSPD: #{error.message}"
    raise error
  end
end
