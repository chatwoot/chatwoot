module CommonCallHelper # rubocop:disable Metrics/ModuleLength
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

  def working_hours_of_resource(call_settings, resource) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
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

  def get_allowed_agent_ids(account, call_settings) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
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

  def ooo_message(call_settings)
    assignment_type = call_settings&.[]('assignmentType')

    if assignment_type == 'agent'
      call_settings&.[]('weekly_availability')&.[]('base')&.[]('out_of_office_message')
    else
      selected_teams = call_settings&.[]('selectedTeams')
      call_settings&.[]('weekly_availability')&.[](selected_teams[0]['id'].to_s)&.[]('out_of_office_message')
    end
  end

  def bot_user(account)
    query = account.users.where('email LIKE ?', 'cx.%@bitespeed.co')
    query.first
  end

  def bot_user?(user)
    user&.email&.match?(/^cx\..*@bitespeed\.co$/)
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

  def build_journey_context(source_context)
    return nil if source_context.blank?

    {
      id: source_context['journeyId'],
      blockId: source_context['blockId'],
      customerJourneyId: source_context['customerJourneyId']
    }
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
end
