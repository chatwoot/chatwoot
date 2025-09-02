class Sla::EvaluateAppliedSlaService
  pattr_initialize [:applied_sla!]

  def perform
    check_sla_thresholds

    # We will calculate again in the next iteration
    return unless applied_sla.conversation.resolved?

    # after conversation is resolved, we will check if the SLA was hit or missed
    handle_hit_sla(applied_sla)
  end

  private

  def check_sla_thresholds
    [:first_response_time_threshold, :next_response_time_threshold, :resolution_time_threshold].each do |threshold|
      next if applied_sla.sla_policy.send(threshold).blank?

      send("check_#{threshold}", applied_sla, applied_sla.conversation, applied_sla.sla_policy)
    end
  end

  def still_within_threshold?(threshold)
    Time.zone.now.to_i < threshold
  end

  def check_first_response_time_threshold(applied_sla, conversation, sla_policy)
    threshold = conversation.created_at.to_i + sla_policy.first_response_time_threshold.to_i
    return if first_reply_was_within_threshold?(conversation, threshold)
    return if still_within_threshold?(threshold)

    handle_missed_sla(applied_sla, 'frt')
  end

  def first_reply_was_within_threshold?(conversation, threshold)
    conversation.first_reply_created_at.present? && conversation.first_reply_created_at.to_i <= threshold
  end

  def check_next_response_time_threshold(applied_sla, conversation, sla_policy)
    # still waiting for first reply, so covered under first response time threshold
    return if conversation.first_reply_created_at.blank?
    # Waiting on customer response, no need to check next response time threshold
    return if conversation.waiting_since.blank?

    threshold = conversation.waiting_since.to_i + sla_policy.next_response_time_threshold.to_i
    return if still_within_threshold?(threshold)

    handle_missed_sla(applied_sla, 'nrt')
  end

  def get_last_message_id(conversation)
    # TODO: refactor the method to fetch last message without reply
    conversation.messages.where(message_type: :incoming).last&.id
  end

  def already_missed?(applied_sla, type, meta = {})
    SlaEvent.exists?(applied_sla: applied_sla, event_type: type, meta: meta)
  end

  def check_resolution_time_threshold(applied_sla, conversation, sla_policy)
    return if conversation.resolved?

    threshold = conversation.created_at.to_i + sla_policy.resolution_time_threshold.to_i
    return if still_within_threshold?(threshold)

    handle_missed_sla(applied_sla, 'rt')
  end

  def handle_missed_sla(applied_sla, type, meta = {})
    meta = { message_id: get_last_message_id(applied_sla.conversation) } if type == 'nrt'
    return if already_missed?(applied_sla, type, meta)

    create_sla_event(applied_sla, type, meta)
    Rails.logger.warn "SLA #{type} missed for conversation #{applied_sla.conversation.id} " \
                      "in account #{applied_sla.account_id} " \
                      "for sla_policy #{applied_sla.sla_policy.id}"

    applied_sla.update!(sla_status: 'active_with_misses') if applied_sla.sla_status != 'active_with_misses'
    
    # Trigger breach alerts
    trigger_breach_alerts(applied_sla, type)
  end

  def handle_hit_sla(applied_sla)
    if applied_sla.active?
      applied_sla.update!(sla_status: 'hit')
      Rails.logger.info "SLA hit for conversation #{applied_sla.conversation.id} " \
                        "in account #{applied_sla.account_id} " \
                        "for sla_policy #{applied_sla.sla_policy.id}"
      
      # Trigger reporting for successful SLA completion
      trigger_sla_reporting(applied_sla, 'resolution', { status: 'hit' })
    else
      applied_sla.update!(sla_status: 'missed')
      Rails.logger.info "SLA missed for conversation #{applied_sla.conversation.id} " \
                        "in account #{applied_sla.account_id} " \
                        "for sla_policy #{applied_sla.sla_policy.id}"
      
      # Trigger reporting for missed SLA
      trigger_sla_reporting(applied_sla, 'resolution', { status: 'missed' })
    end
  end

  def create_sla_event(applied_sla, event_type, meta = {})
    SlaEvent.create!(
      applied_sla: applied_sla,
      conversation: applied_sla.conversation,
      event_type: event_type,
      meta: meta,
      account: applied_sla.account,
      inbox: applied_sla.conversation.inbox,
      sla_policy: applied_sla.sla_policy
    )
  end

  def trigger_breach_alerts(applied_sla, type)
    breach_type = case type
                  when 'frt'
                    'first_response_time'
                  when 'nrt'
                    'next_response_time'
                  when 'rt'
                    'resolution_time'
                  else
                    type
                  end

    Sla::BreachAlertService.new(
      applied_sla: applied_sla,
      breach_type: breach_type
    ).perform

    # Also trigger reporting for the breach
    trigger_sla_reporting(applied_sla, breach_type, { status: 'breach', breach_type: type })
  rescue => e
    Rails.logger.error "Failed to trigger SLA breach alerts: #{e.message}"
  end

  def trigger_sla_reporting(applied_sla, event_type, event_data)
    Sla::EventReportingService.new(
      applied_sla: applied_sla,
      event_type: event_type,
      event_data: event_data
    ).perform
  rescue => e
    Rails.logger.error "Failed to trigger SLA event reporting: #{e.message}"
  end
end
