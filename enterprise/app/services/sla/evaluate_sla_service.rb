class Sla::EvaluateSlaService
  pattr_initialize [:applied_sla!]

  def perform
    conversation = applied_sla.conversation
    sla_policy = applied_sla.sla_policy

    check_first_response_time(applied_sla, conversation, sla_policy)
    check_next_response_time(applied_sla, conversation, sla_policy)
    check_resolution_time(applied_sla, conversation, sla_policy)
  end

  private

  def check_first_response_time(applied_sla, conversation, sla_policy)
    return if conversation.resolved?
    return if sla_policy.first_response_time_threshold.blank?

    threshold = conversation.created_at.to_i + sla_policy.first_response_time_threshold.to_i
    # If first reply is present, compare it with threshold
    # else use current.time
    return if first_reply_within_threshold?(conversation, threshold)
    return unless Time.now.to_i > threshold

    handle_missed_sla(applied_sla)
  end

  def first_reply_within_threshold?(conversation, threshold)
    conversation.first_reply_created_at.present? && conversation.first_reply_created_at.to_i <= threshold
  end

  def check_next_response_time(applied_sla, conversation, sla_policy)
    return if conversation.resolved?
    unless sla_policy.next_response_time_threshold.present? && conversation.first_reply_created_at.present? && conversation.waiting_since.present?
      return
    end

    threshold = conversation.waiting_since.to_i + sla_policy.next_response_time_threshold.to_i
    return if next_reply_within_threshold?(threshold)

    handle_missed_sla(applied_sla)
  end

  def next_reply_within_threshold?(threshold)
    Time.now.to_i < threshold
  end

  def check_resolution_time(applied_sla, conversation, sla_policy)
    return unless sla_policy.resolution_time_threshold.present? && conversation.resolved?

    threshold = sla_policy.resolution_time_threshold.to_i
    resolution_time = conversation.account.reporting_events.where(name: 'conversation_resolved').last.value

    if conversation_resolved_within_threshold?(resolution_time, threshold)
      handle_hit_sla(applied_sla)
    else
      handle_missed_sla(applied_sla)
    end
  end

  def conversation_resolved_within_threshold?(resolution_time, threshold)
    resolution_time < threshold
  end

  def handle_missed_sla(applied_sla)
    applied_sla.update(sla_status: 'missed')
    Rails.logger.warn "SLA missed for conversation #{applied_sla.conversation.id} " \
                      "in account #{applied_sla.conversation.account_id} " \
                      "for sla_policy #{applied_sla.sla_policy.id}"
  end

  def handle_hit_sla(applied_sla)
    applied_sla.update(sla_status: 'hit')
    Rails.logger.info "SLA hit for conversation #{applied_sla.conversation.id} " \
                      "in account #{applied_sla.conversation.account_id} " \
                      "for sla_policy #{applied_sla.sla_policy.id}"
  end
end
