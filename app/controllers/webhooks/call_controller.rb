# app/controllers/webhooks/call_controller.rb
require 'json'
require 'httparty'

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity
class Webhooks::CallController < ActionController::API
  include CallHelper
  def handle_call_callback
    payload = request.body.read
    parsed_body = JSON.parse(payload)

    conversation = Conversation.where({
                                        account_id: params[:account_id],
                                        inbox_id: params[:inbox_id],
                                        display_id: params[:conversation_id]
                                      }).first

    send_call_log_to_bspd(parsed_body, conversation, params[:account_id])

    call_log_message = get_call_log_string(parsed_body)

    conversation.messages.create!(private_message_params(call_log_message, conversation))

    head :ok
  end

  def welcome_message
    Rails.logger.info "Welcome Message Requested: #{params.inspect}"

    account = Account.where("custom_attributes->>'call_config' IS NOT NULL")
                     .find_by("custom_attributes->'call_config'->>'callerId' = ?", params[:To])

    if account.blank?
      render json: { error: 'Account not found for this caller ID' }, status: :bad_request
      return
    end

    call_settings = account&.custom_attributes&.[]('calling_settings')

    call_message = if working_hours?(call_settings)
                     Rails.logger.info "Welcome message: #{call_settings&.[]('welcomeMessage')}"
                     call_settings&.[]('welcomeMessage')
                   else
                     Rails.logger.info "Out of office message: #{ooo_message(call_settings)}"
                     ooo_message(call_settings)
                   end

    render plain: call_message, status: :ok
  end

  def handle_incoming_call
    Rails.logger.info "Incoming call received: #{params.inspect}"

    account = Account.where("custom_attributes->>'call_config' IS NOT NULL")
                     .find_by("custom_attributes->'call_config'->>'callerId' = ?", params[:To])

    if account.blank?
      render json: { error: 'Account not found for this caller ID' }, status: :bad_request
      return
    end

    call_config = account&.custom_attributes&.[]('call_config')
    call_settings = account&.custom_attributes&.[]('calling_settings')

    if call_config.blank?
      render json: { error: 'Call config not found' }, status: :bad_request
      return
    end

    # Find contact by matching last 10 digits of phone number
    indian_phone_number = params[:From].gsub(/^0/, '+91')

    # Find or create contact based on the caller number
    contact = Contact.find_by(account_id: account.id, phone_number: indian_phone_number)
    if contact.blank?
      contact = account.contacts.new(name: params[:From], email: '', phone_number: indian_phone_number)
      contact.save!
    end

    # Find API inbox
    matching_inboxes = Inbox.where(account_id: account.id, channel_type: 'Channel::Api')
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

    unless working_hours?(call_settings)
      render json: { error: 'Account is not in working hours' }, status: :bad_request
      return
    end

    if conversation&.assignee.is_a?(User) && !bot_user?(conversation.assignee)
      # Case: Human agent assigned already
      assigned_agent = conversation.assignee

      # Prepare response for Exotel
      response = {
        destination: {
          'numbers': ["0#{assigned_agent.custom_attributes['phone_number']}"].compact
        },
        record: true,
        recording_channels: 'dual',
        max_ringing_duration: 45,
        max_conversation_duration: 900,
        music_on_hold: { type: 'default_tone' }
      }

      Rails.logger.info "Response: #{response.inspect}"

      render json: response
      return
    end

    # now i need to get an array of agents (sorted by round robin)
    allowed_agent_ids = get_allowed_agent_ids(account, call_settings)

    Rails.logger.info "ALLOWED AGENT IDS: #{allowed_agent_ids.inspect}"

    assignees = AutoAssignment::CallingAgentAssignmentService.new(conversation: conversation, allowed_agent_ids: allowed_agent_ids).perform

    Rails.logger.info "Assignees: #{assignees.inspect}"

    if assignees.blank?
      # Missed Call
      response = {
        record: true,
        destination: {
          'numbers': []
        },
        max_ringing_duration: 45,
        max_conversation_duration: 900,
        music_on_hold: { type: 'default_tone' }
      }

      Rails.logger.info "Response: #{response.inspect}"

      render json: response
      return
    end

    assignee_phone_numbers = assignees.filter_map { |agent| "0#{agent.custom_attributes['phone_number']}" }

    # Prepare response for Exotel
    response = {
      destination: {
        numbers: assignee_phone_numbers
      },
      record: true,
      max_ringing_duration: 45,
      max_conversation_duration: 900,
      music_on_hold: { type: 'default_tone' }
    }

    parallel_ringing = call_settings['assignmentRule'] == 'parallel'

    if parallel_ringing
      parallel_ringing = {
        activate: true,
        max_parallel_attempts: 1
      }

      response[:parallel_ringing] = parallel_ringing
    end

    Rails.logger.info "Response: #{response.inspect}"

    render json: response
  end

  def missed_call_message
    Rails.logger.info "Missed Call Message Requested: #{params.inspect}
     "

    account = Account.where("custom_attributes->>'call_config' IS NOT NULL")
                     .find_by("custom_attributes->'call_config'->>'callerId' = ?", params[:To])

    if account.blank?
      render json: { error: 'Account not found for this caller ID' }, status: :bad_request
      return
    end

    call_settings = account&.custom_attributes&.[]('calling_settings')

    missed_call_message = if working_hours?(call_settings)
                            call_settings&.[]('missedCallMessage') || 'Unfortunatly, all of our agents are currently busy. Please try again later.'
                          end

    render plain: missed_call_message, status: :ok
  end

  def handle_incoming_call_callback
    Rails.logger.info "Inbound call callback received: #{params.inspect}"

    account = Account.where("custom_attributes->>'call_config' IS NOT NULL")
                     .find_by("custom_attributes->'call_config'->>'callerId' = ?", params[:To])

    if account.blank?
      render json: { error: 'Account not found for this caller ID' }, status: :bad_request
      return
    end

    call_config = account&.custom_attributes&.[]('call_config')

    if call_config.blank?
      render json: { error: 'Call config not found' }, status: :bad_request
      return
    end

    indian_phone_number = params[:From].gsub(/^0/, '+91')
    contact = Contact.find_by(account_id: account.id, phone_number: indian_phone_number)

    if contact.blank?
      render json: { error: 'Contact not found' }, status: :bad_request
      return
    end

    conversation = Conversation.where(
      contact_id: contact.id,
      account_id: account.id
    ).order(created_at: :desc).first

    mark_conversation_as_inbound_call(conversation)

    agent_phone = params[:DialWhomNumber]

    agent = account.users.find_by("custom_attributes->>'phone_number' LIKE ?", "%#{agent_phone.gsub(/^0/, '')}%")

    conversation.update!(assignee: agent)

    total_call_duration = params[:DialCallDuration].to_i
    start_time = Time.strptime(params[:StartTime], '%Y-%m-%d %H:%M:%S', 'Asia/Kolkata').utc

    handled_call_duration = get_on_call_duration(params[:Legs])

    add_handling_time_reporting_event(conversation, handled_call_duration, start_time) if handled_call_duration.positive?

    wait_time = total_call_duration - handled_call_duration

    add_waiting_time_reporting_event(conversation, wait_time, start_time) if wait_time.positive?

    call_log_message = get_inbound_call_log_string(params[:DialCallStatus], params[:Legs], params[:RecordingUrl])

    conversation.messages.create!(private_message_params(call_log_message, conversation))

    head :ok
  end

  def handle_missed_call_callback
    Rails.logger.info "Missed call callback received: #{params.inspect}"

    account = Account.where("custom_attributes->>'call_config' IS NOT NULL")
                     .find_by("custom_attributes->'call_config'->>'callerId' = ?", params[:To])

    if account.blank?
      render json: { error: 'Account not found for this caller ID' }, status: :bad_request
      return
    end

    call_settings = account&.custom_attributes&.[]('calling_settings')
    call_config = account&.custom_attributes&.[]('call_config')

    if call_config.blank?
      render json: { error: 'Call config not found' }, status: :bad_request
      return
    end

    indian_phone_number = params[:From].gsub(/^0/, '+91')
    contact = Contact.find_by(account_id: account.id, phone_number: indian_phone_number)

    if contact.blank?
      render json: { error: 'Contact not found' }, status: :bad_request
      return
    end

    conversation = Conversation.where(
      contact_id: contact.id,
      account_id: account.id
    ).order(created_at: :desc).first

    mark_conversation_as_inbound_call(conversation)

    wait_time = params[:DialCallDuration].to_i
    start_time = Time.strptime(params[:StartTime], '%Y-%m-%d %H:%M:%S', 'Asia/Kolkata').utc

    add_waiting_time_reporting_event(conversation, wait_time, start_time) if wait_time.positive?

    if working_hours?(call_settings)
      mark_conversation_as_missed_call(conversation, 'busy')
    else
      mark_conversation_as_missed_call(conversation, 'ooo')
    end
  end

  def private_message_params(content, conversation)
    { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :outgoing, content: content, private: true }
  end

  private

  def send_call_log_to_bspd(parsed_body, conversation, account_id)
    Rails.logger.info "Sending call log to BSPD: #{parsed_body.inspect}"
    call_report = build_call_report(parsed_body, conversation, account_id)
    send_report_to_bspd(call_report)
    Rails.logger.info "Call log sent to BSPD: #{call_report.inspect}"
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

  def handle_conversation_creation(latest_conversation, contact, inbox)
    if latest_conversation.nil?
      # Case: New contact or Existing contact with no conversations
      create_new_conversation(contact, inbox)
    elsif latest_conversation.resolved?
      if latest_conversation.assignee.is_a?(User) && !bot_user?(latest_conversation.assignee)
        # Case: Existing contact, Resolved conversation, Human agent assigned
        latest_conversation.update!(status: :open)
        latest_conversation
      else
        # Case: Existing contact, Resolved conversation, Bot assigned or no assignee
        create_new_conversation(contact, inbox)
      end
    else
      # Case: Existing contact, Not resolved conversation
      latest_conversation.update!(status: :open)
      latest_conversation
    end
  end

  def create_new_conversation(contact, inbox)
    contact_inbox = ContactInboxBuilder.new(
      contact: contact,
      inbox: inbox,
      source_id: SecureRandom.uuid
    ).perform

    Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      status: :open
    )
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
  end

  def mark_conversation_as_missed_call(conversation, reason = 'busy')
    add_missed_call_label(conversation)

    if reason == 'busy'
      conversation.messages.create!(private_message_params('Call was missed due to no agents available', conversation))
    else
      conversation.messages.create!(private_message_params('Call was missed due to out of office hours', conversation))
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

  def bot_user?(user)
    user&.email&.match?(/^cx\..*@bitespeed\.co$/)
  end

  def bot_user(account)
    query = account.users.where('email LIKE ?', 'cx.%@bitespeed.co')
    query.first
  end

  def working_hours?(call_settings)
    working_hours_enabled = call_settings&.[]('weekly_availability')&.[]('working_hours_enabled')

    return true unless working_hours_enabled

    assignment_type = call_settings&.[]('assignmentType')

    if assignment_type == 'agent'
      working_hours_of_resource(call_settings, 'base')
    else
      selected_teams = call_settings&.[]('selectedTeams')

      selected_teams.each do |team|
        return true if working_hours_of_resource(call_settings, team['id'])
      end

      false
    end
  end

  def get_allowed_agent_ids(account, call_settings)
    working_hours_enabled = call_settings&.[]('weekly_availability')&.[]('working_hours_enabled')

    # handled when working hours are not enabled
    return account.users.pluck(:id) unless working_hours_enabled

    in_working_hours = working_hours?(call_settings)

    # handled when not in working hours
    return [] unless in_working_hours

    assignment_type = call_settings&.[]('assignmentType')

    allowed_agent_ids = []

    if assignment_type == 'agent'
      selected_agents = call_settings&.[]('selectedAgents')
      allowed_agent_ids.concat(selected_agents.pluck('id'))
    else
      selected_teams = call_settings&.[]('selectedTeams')
      selected_teams.each do |team|
        next unless working_hours_of_resource(call_settings, team['id'])

        # get agents from team
        team = account.teams.find(team['id'])
        team_members = team.team_members.pluck(:user_id)
        allowed_agent_ids.concat(team_members)
      end
    end

    allowed_agent_ids
  end

  def working_hours_of_resource(call_settings, resource)
    Rails.logger.info "Call settings: #{call_settings.inspect}"
    Rails.logger.info "Working hours of resource: #{resource}"
    Rails.logger.info "Weekly availability: #{call_settings&.[]('weekly_availability').inspect}"

    # Convert resource to string when accessing the hash
    weekly_availability = call_settings&.[]('weekly_availability')&.[](resource.to_s)

    Rails.logger.info "Weekly availability: #{weekly_availability.inspect}"

    working_hours = weekly_availability&.[]('working_hours')
    timezone = weekly_availability&.[]('timezone')

    Rails.logger.info "Working hours: #{working_hours.inspect}"
    Rails.logger.info "Timezone: #{timezone.inspect}"

    today = Time.zone.now.in_time_zone(timezone).to_date.wday
    current_time = Time.zone.now.in_time_zone(timezone)

    Rails.logger.info "Today: #{today}"
    Rails.logger.info "Current time: #{current_time.inspect}"

    today_working_hour = working_hours.find { |hour| hour.[]('day_of_week') == today }

    Rails.logger.info "Today working hour: #{today_working_hour.inspect}"

    return true if today_working_hour.blank?

    return false if today_working_hour.[]('closed_all_day')

    open_hour = today_working_hour.[]('open_hour')
    open_minutes = today_working_hour.[]('open_minutes')
    close_hour = today_working_hour.[]('close_hour')
    close_minutes = today_working_hour.[]('close_minutes')

    open_time = Time.zone.now.in_time_zone(timezone).change({ hour: open_hour, min: open_minutes })
    close_time = Time.zone.now.in_time_zone(timezone).change({ hour: close_hour, min: close_minutes })

    current_time.between?(open_time, close_time)
  end

  def ooo_message(call_settings)
    assignment_type = call_settings&.[]('assignmentType')

    if assignment_type == 'agent'
      call_settings&.[]('weekly_availability')&.[]('base')&.[]('out_of_office_message')
    else
      selected_teams = call_settings&.[]('selectedTeams')
      call_settings&.[]('weekly_availability')&.[](selected_teams[0]['id'].to_s)&.[]('out_of_office_message')
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/PerceivedComplexity
