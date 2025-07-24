require 'json'
require 'httparty'

class Webhooks::CallAlohaaController < ActionController::API # rubocop:disable Metrics/ClassLength
  include CommonCallHelper
  include CallAlohaaHelper

  def handle_call_callback # rubocop:disable Metrics/AbcSize
    parsed_body = parse_request_body

    Rails.logger.info("parsed_bodyForAlohaa #{parsed_body.inspect}")

    account = find_account(parsed_body)
    Rails.logger.info("account #{account.inspect}")
    return render json: { error: 'Account not found' }, status: :not_found if account.blank?

    is_inbound = parsed_body['call_type'] == 'incoming'

    contact = find_contact_or_create_contact(account, parsed_body, is_inbound)
    Rails.logger.info("contact #{contact.inspect}")

    if is_inbound
      handle_incoming_call(account, contact, parsed_body) if call_completion_webhook?(parsed_body)
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

  def handle_incoming_call(account, contact, parsed_body) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
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

    is_missed_call = parsed_body['call_status'] == 'notanswered'
    Rails.logger.info("conversationData, #{conversation.inspect}")
    Rails.logger.info("is_missed_call, #{is_missed_call}")
    if is_missed_call
      handle_incoming_missed_call_callback(conversation, parsed_body, account)
    else
      handle_incoming_callback(conversation, parsed_body, account)
    end
  end

  def handle_incoming_callback(conversation, parsed_body, account) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    mark_conversation_as_inbound_call(conversation)

    dial_on_agent = parsed_body['webhook_type'] == 'dial_on_agent'
    if dial_on_agent
      conversation.messages.create!(private_message_params('User Initiated Inbound Call', conversation, parsed_body))
      return
    end

    agent_phone = parsed_body['receiver_number']

    if agent_phone.present?
      agent = account.users.find_by("custom_attributes->>'phone_number' LIKE ?", "%#{agent_phone.gsub(/^0/, '')}%")
      conversation.update!(assignee: agent)
    end

    total_call_duration = convert_duration_to_seconds(parsed_body['call_duration'])

    start_time = Time.parse(parsed_body['received_at']).in_time_zone('Asia/Kolkata').utc

    handled_call_duration = convert_duration_to_seconds(parsed_body['call_duration'])

    add_handling_time_reporting_event(conversation, handled_call_duration, start_time) if handled_call_duration.positive?

    wait_time = total_call_duration - handled_call_duration

    add_waiting_time_reporting_event(conversation, wait_time, start_time) if wait_time.positive?

    call_log_message = get_call_log_string_alohaa(parsed_body)

    conversation.messages.create!(private_message_params(call_log_message, conversation, parsed_body))

    send_call_log_to_bspd(parsed_body, conversation, account)

    head :ok
  end

  def handle_incoming_missed_call_callback(conversation, parsed_body, account)
    mark_conversation_as_inbound_call(conversation)

    wait_time = convert_duration_to_seconds(parsed_body['call_duration'])

    start_time = Time.parse(parsed_body['received_at']).in_time_zone('Asia/Kolkata').utc

    add_waiting_time_reporting_event(conversation, wait_time, start_time) if wait_time.positive?

    call_settings = account&.custom_attributes&.[]('calling_settings')

    if working_hours?(call_settings)
      mark_conversation_as_missed_call(conversation, parsed_body, 'busy')
    else
      mark_conversation_as_missed_call(conversation, parsed_body, 'ooo')
    end
  end

  def add_missed_call_label(conversation)
    Label.find_or_create_by!(
      account: conversation.account,
      title: 'missed-call'
    ) do |l|
      l.description = 'Automatically added to conversations with missed calls'
      l.show_on_sidebar = true
      l.color = '#7C21D7' # Default color
    end

    conversation.add_labels(['missed-call'])
    Rails.logger.info('LabelAdded')
  end

  def mark_conversation_as_missed_call(conversation, parsed_body, reason = 'busy') # rubocop:disable Metrics/MethodLength
    add_missed_call_label(conversation)

    if reason == 'busy'
      conversation.messages.create!(private_message_params('Call was missed due to no agents available', conversation, parsed_body))
    else
      conversation.messages.create!(private_message_params('Call was missed due to out of office hours', conversation, parsed_body))
    end

    # TODO: - If an agent is assigned to the conversation, notify similar to calling Nudge

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
    Rails.logger.info('Missed Callback finished')
  end

  def parse_request_body
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    {}
  end

  def call_completion_webhook?(parsed_body)
    parsed_body['webhook_type'] == 'call_completion'
  end

  def find_account(parsed_body)
    did_number = parsed_body['did_number']
    Account.where("custom_attributes->>'call_config' IS NOT NULL")
           .find_by("custom_attributes->'call_config'->'externalProviderConfig'->>'did_number' = ?", did_number)

    # Another way
    # organisation_id = parsed_body['organisation_id']
    # Account.where("custom_attributes->>'call_config' IS NOT NULL")
    # .find_by("custom_attributes->'call_config'->'externalProviderConfig'->>'organisation_id' = ?", organisation_id)
  end

  def find_contact_or_create_contact(account, parsed_body, is_inbound)
    client_no = if is_inbound
                  "+91#{parsed_body['caller_number'].to_s.gsub(/^(\+91|0)+/, '')}"
                else
                  "+91#{parsed_body['receiver_number'].to_s.gsub(/^(\+91|0)+/, '')}"
                end
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
    call_log_message = get_call_log_string_alohaa(parsed_body)
    conversation.messages.create!(private_message_params(call_log_message, conversation, parsed_body))
  end

  def private_message_params(content, conversation, parsed_body)
    received_at = parsed_body['received_at']
    time = received_at.present? ? Time.parse(received_at).in_time_zone : Time.current

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
    call_report = build_call_report_alohaa(parsed_body, conversation, account)
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
