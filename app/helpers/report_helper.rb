module ReportHelper # rubocop:disable Metrics/ModuleLength
  private

  def scope
    case params[:type]
    when :account
      account
    when :inbox
      inbox
    when :agent
      user
    when :label
      label
    when :team
      team
    end
  end

  def conversations_count
    (get_grouped_values conversations).count
  end

  def incoming_messages_count
    (get_grouped_values incoming_messages).count
  end

  def outgoing_messages_count
    (get_grouped_values outgoing_messages).count
  end

  def resolutions_count
    (get_grouped_values resolutions).count
  end

  def bot_resolutions_count
    (get_grouped_values bot_resolutions).count
  end

  def bot_handoffs_count
    (get_grouped_values bot_handoffs).count
  end

  def conversations
    if filter_by_team?
      conversations_by_team
    else
      scope.conversations.where(account_id: account.id, created_at: range)
    end
  end

  def conversations_by_team
    scope.conversations.joins(:assignee_team_members)
         .where(account_id: account.id, created_at: range, team_members: { team_id: team.id })
         .or(
           scope.conversations.joins(:assignee_team_members).where(account_id: account.id, created_at: range, team_id: team.id)
         )
  end

  def incoming_messages
    if filter_by_team?
      incoming_messages_by_team
    else
      scope.messages.where(account_id: account.id, created_at: range).incoming.unscope(:order)
    end
  end

  def incoming_messages_by_team
    scope.messages.joins(:conversation, :assignee_team_members).where(account_id: account.id, created_at: range,
                                                                      conversations: { team_id: team.id }).incoming.unscope(:order)
         .or(
           # case when assignee belongs to a team
           scope.messages.joins(:conversation, :assignee_team_members)
                .where(account_id: account.id, created_at: range, team_members: { team_id: team.id }).incoming.unscope(:order)
         )
  end

  def outgoing_messages
    if filter_by_team?
      outgoing_messages_by_team
    else
      scope.messages.where(account_id: account.id, created_at: range).outgoing.unscope(:order)
    end
  end

  def outgoing_messages_by_team
    scope.messages.joins(:conversation, :assignee_team_members).where(account_id: account.id, created_at: range,
                                                                      conversations: { team_id: team.id }).outgoing.unscope(:order)
         .or(
           # case when assignee belongs to a team
           scope.messages.joins(:conversation, :assignee_team_members)
                .where(account_id: account.id, created_at: range, team_members: { team_id: team.id }).outgoing.unscope(:order)
         )
  end

  def resolutions
    if filter_by_team?
      resolutions_by_team
    else
      scope.reporting_events.joins(:conversation).select(:conversation_id).where(account_id: account.id, name: :conversation_resolved,
                                                                                 conversations: { status: :resolved }, created_at: range).distinct
    end
  end

  def resolutions_by_team
    scope.reporting_events
         .joins(:conversation, :team_members).select(:conversation_id)
         .where(account_id: account.id, name: :conversation_resolved, conversations: { status: :resolved,
                                                                                       team_id: team.id }, created_at: range).distinct
         .or(
           # case when assignee belongs to a team
           scope.reporting_events
                .joins(:conversation, :team_members).select(:conversation_id)
                .where(account_id: account.id, name: :conversation_resolved,
                       conversations: { status: :resolved }, created_at: range, team_members: { team_id: team.id })
                .distinct
         )
  end

  def bot_resolutions
    scope.reporting_events.joins(:conversation).select(:conversation_id).where(account_id: account.id, name: :conversation_bot_resolved,
                                                                               conversations: { status: :resolved }, created_at: range).distinct
  end

  def bot_handoffs
    scope.reporting_events.joins(:conversation).select(:conversation_id).where(account_id: account.id, name: :conversation_bot_handoff,
                                                                               created_at: range).distinct
  end

  def avg_first_response_time
    reporting_events = if filter_by_team?
                         scope.reporting_events.joins(:team_members)
                              .where(name: 'first_response', account_id: account.id, team_members: { team_id: team.id })
                       else
                         scope.reporting_events.where(name: 'first_response', account_id: account.id)
                       end
    grouped_reporting_events = (get_grouped_values reporting_events)
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def reply_time
    reporting_events =
      if filter_by_team?
        scope.reporting_events.joins(:team_members)
             .where(name: 'reply_time', account_id: account.id, team_members: { team_id: team.id })
      else
        scope.reporting_events.where(name: 'reply_time', account_id: account.id)
      end
    grouped_reporting_events = (get_grouped_values reporting_events)
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def avg_resolution_time
    reporting_events = if filter_by_team?
                         scope.reporting_events.joins(:team_members)
                              .where(name: 'conversation_resolved', account_id: account.id, team_members: { team_id: team.id })
                       else
                         scope.reporting_events
                              .where(name: 'conversation_resolved', account_id: account.id)
                       end
    grouped_reporting_events = (get_grouped_values reporting_events)
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def avg_resolution_time_summary
    reporting_events =
      if filter_by_team?
        # Filter by team associated with the user
        scope.reporting_events.joins(:team_members)
             .where(name: 'conversation_resolved', account_id: account.id, created_at: range, team_members: { team_id: team.id })
      else
        scope.reporting_events.where(name: 'conversation_resolved', account_id: account.id, created_at: range)
      end
    avg_rt = if params[:business_hours].present?
               reporting_events.average(:value_in_business_hours)
             else
               reporting_events.average(:value)
             end

    return 0 if avg_rt.blank?

    avg_rt
  end

  def reply_time_summary
    reporting_events =
      if filter_by_team?
        scope.reporting_events.joins(:team_members)
             .where(name: 'reply_time', account_id: account.id, created_at: range, team_members: { team_id: team.id })
      else
        scope.reporting_events
             .where(name: 'reply_time', account_id: account.id, created_at: range)
      end
    reply_time = params[:business_hours] ? reporting_events.average(:value_in_business_hours) : reporting_events.average(:value)

    return 0 if reply_time.blank?

    reply_time
  end

  def avg_first_response_time_summary
    reporting_events =
      if filter_by_team?
        # Filter by team associated with the user
        scope.reporting_events.joins(:team_members)
             .where(name: 'first_response', account_id: account.id, created_at: range, team_members: { team_id: team.id })
      else
        scope.reporting_events.where(name: 'first_response', account_id: account.id, created_at: range)
      end

    avg_frt = if params[:business_hours].present?
                reporting_events.average(:value_in_business_hours)
              else
                reporting_events.average(:value)
              end

    return 0 if avg_frt.blank?

    avg_frt
  end

  def filter_by_team?
    params[:team_id].present?
  end
end
