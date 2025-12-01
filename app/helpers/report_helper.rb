# rubocop:disable Metrics/ModuleLength
module ReportHelper
  include OnlineStatusHelper

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
    if params[:assignee_id].present?
      scope.conversations.where(account_id: account.id, created_at: range, assignee_id: params[:assignee_id])
    else
      scope.conversations.where(account_id: account.id, created_at: range)
    end
  end

  def incoming_messages
    scope.messages.where(account_id: account.id, created_at: range).incoming.unscope(:order)
  end

  def outgoing_messages
    scope.messages.where(account_id: account.id, created_at: range).outgoing.unscope(:order)
  end

  # rubocop:disable Metrics/MethodLength
  def resolutions
    if params[:assignee_id].present?
      scope.reporting_events.joins(:conversation)
           .select(:conversation_id)
           .where(
             account_id: account.id,
             name: :conversation_resolved,
             user_id: params[:assignee_id],
             conversations: { status: :resolved },
             created_at: range
           ).distinct
    else
      scope.reporting_events.joins(:conversation)
           .select(:conversation_id)
           .where(
             account_id: account.id,
             name: :conversation_resolved,
             conversations: { status: :resolved },
             created_at: range
           ).distinct
    end
  end
  # rubocop:enable Metrics/MethodLength

  def bot_resolutions
    scope.reporting_events.joins(:conversation).select(:conversation_id).where(account_id: account.id, name: :conversation_bot_resolved,
                                                                               conversations: { status: :resolved }, created_at: range).distinct
  end

  def bot_handoffs
    scope.reporting_events.joins(:conversation).select(:conversation_id).where(account_id: account.id, name: :conversation_bot_handoff,
                                                                               created_at: range).distinct
  end

  def avg_first_response_time
    grouped_reporting_events = (get_grouped_values scope.reporting_events.where(name: 'first_response', account_id: account.id))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def reply_time
    grouped_reporting_events = (get_grouped_values scope.reporting_events.where(name: 'reply_time', account_id: account.id))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  def avg_resolution_time
    grouped_reporting_events = (get_grouped_values scope.reporting_events.where(name: 'conversation_resolved', account_id: account.id))
    return grouped_reporting_events.average(:value_in_business_hours) if params[:business_hours]

    grouped_reporting_events.average(:value)
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def avg_resolution_time_summary
    reporting_events = if params[:assignee_id].present?
                         scope.reporting_events.joins(:conversation)
                              .select(:value, :value_in_business_hours)
                              .where(
                                account_id: account.id,
                                name: :conversation_resolved,
                                user_id: params[:assignee_id],
                                conversations: { status: :resolved },
                                created_at: range
                              )
                       else
                         scope.reporting_events.joins(:conversation)
                              .select(:value, :value_in_business_hours)
                              .where(
                                account_id: account.id,
                                name: :conversation_resolved,
                                conversations: { status: :resolved },
                                created_at: range
                              )
                       end
    avg_rt = if params[:business_hours] == true
               reporting_events.average(:value_in_business_hours)
             else
               reporting_events.average(:value)
             end

    return 0 if avg_rt.blank?

    avg_rt
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def reply_time_summary
    reporting_events = scope.reporting_events
                            .where(name: 'reply_time', account_id: account.id, created_at: range)
    reply_time = params[:business_hours] == true ? reporting_events.average(:value_in_business_hours) : reporting_events.average(:value)

    return 0 if reply_time.blank?

    reply_time
  end

  def avg_first_response_time_summary
    if params[:assignee_id].present?
      reporting_events = scope.reporting_events
                              .where(name: 'first_response', account_id: account.id, created_at: range, user_id: params[:assignee_id])
    else
      reporting_events = scope.reporting_events
                              .where(name: 'first_response', account_id: account.id, created_at: range)
    end
    avg_frt = if params[:business_hours] == true
                reporting_events.average(:value_in_business_hours)
              else
                reporting_events.average(:value)
              end

    return 0 if avg_frt.blank?

    avg_frt
  end

  def online_time_summary
    audit_logs = Audited::Audit.where(user_id: scope.id, associated_id: account.id, created_at: range, auditable_type: 'AccountUser',
                                      action: 'update').order(:created_at)

    return 0 if audit_logs.blank?

    ot = calculate_time_for_status(audit_logs, 0)

    return 0 if ot.blank?

    ot
  end

  def busy_time_summary
    audit_logs = Audited::Audit.where(user_id: scope.id, associated_id: account.id, created_at: range, auditable_type: 'AccountUser',
                                      action: 'update').order(:created_at)

    return 0 if audit_logs.blank?

    bt = calculate_time_for_status(audit_logs, 2)

    return 0 if bt.blank?

    bt
  end
end
# rubocop:enable Metrics/ModuleLength
