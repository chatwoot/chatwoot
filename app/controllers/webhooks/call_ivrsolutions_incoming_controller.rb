require 'json'
require 'httparty'

# rubocop:disable Metrics/AbcSize, Lint/MissingCopEnableDirective
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity
class Webhooks::CallIvrsolutionsIncomingController < ActionController::API
  include CommonCallHelper
  def welcome_message
    Rails.logger.info "Welcome Message Requested: #{params.inspect}"

    account = Account.find_by(id: params[:account_id])

    if account.blank?
      render json: { error: 'Account not found for this account id' }, status: :bad_request
      return
    end

    call_settings = account&.custom_attributes&.[]('calling_settings')

    if working_hours?(call_settings)
      Rails.logger.info "Welcome message: #{call_settings&.[]('welcomeMessage')}"
      call_settings&.[]('welcomeMessage')
    else
      Rails.logger.info "Out of office message: #{ooo_message(call_settings)}"
      ooo_message(call_settings)
    end
  end

  def handle_incoming_call
    Rails.logger.info "Incoming call received: #{params.inspect}"

    account = Account.find_by(id: params[:account_id])

    if account.blank?
      render json: { error: 'Account not found for this account id' }, status: :bad_request
      return
    end

    call_config = account&.custom_attributes&.[]('call_config')
    call_settings = account&.custom_attributes&.[]('calling_settings')

    if call_config.blank?
      render json: { error: 'Call config not found' }, status: :bad_request
      return
    end

    indian_phone_number = "+91#{params[:phone]}"

    contact = Contact.find_by(account_id: account.id, phone_number: indian_phone_number)
    # Rails.logger.info("Contact Found, #{contact.inspect}")
    # return :ok

    if contact.blank?
      contact = account.contacts.new(name: params[:phone], email: '', phone_number: indian_phone_number)
      contact.save!
    end

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
      # Handle out of office scenario - provide out of office message instead of error
      out_of_office_msg = ooo_message(call_settings)
      out_of_office_msg = 'We are currently closed. Please call during business hours.' if out_of_office_msg.blank?

      response = {
        message: out_of_office_msg,
        status: false
      }

      Rails.logger.info "Out of office response: #{response.inspect}"

      render json: response
      return
    end

    if conversation&.assignee.is_a?(User) && !bot_user?(conversation.assignee)
      assigned_agent = conversation.assignee

      response = {
        message: welcome_message,
        agents_phone: "0#{assigned_agent.custom_attributes['phone_number']}",
        status: true
      }

      Rails.logger.info "Response: #{response.inspect}"

      render json: response
      return
    end

    allowed_agent_ids = get_allowed_agent_ids(account, call_settings)

    Rails.logger.info "ALLOWED AGENT IDS: #{allowed_agent_ids.inspect}"

    assignees = AutoAssignment::CallingAgentAssignmentService.new(conversation: conversation, allowed_agent_ids: allowed_agent_ids).perform

    Rails.logger.info "Assignees: #{assignees.inspect}"

    if assignees.blank?
      # Missed Call
      response = {
        message: 'No Agent Available to take call',
        status: false
      }

      Rails.logger.info "Response: #{response.inspect}"

      render json: response
      return
    end

    assignee_phone_numbers = assignees.filter_map do |agent|
      "0#{agent.custom_attributes['phone_number']}" if agent.custom_attributes['phone_number'].present?
    end.join(',')

    response = {
      message: welcome_message,
      agents_phone: assignee_phone_numbers,
      status: true
    }

    render json: response
  end

  private

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

  def bot_user?(user)
    user&.email&.match?(/^cx\..*@bitespeed\.co$/)
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
