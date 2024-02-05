class MonitorSlaJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    AppliedSla.where(sla_status: 'active').all.find_each(batch_size: 100) do |applied_sla|
      process_sla(applied_sla)
    end
  end

  private

  def process_sla(applied_sla)
    conversation = Conversation.find_by(id: applied_sla.conversation_id)
    sla_policy = SlaPolicy.find_by(id: applied_sla.sla_policy_id)

    check_first_response_time(applied_sla, conversation, sla_policy)
    check_next_response_time(applied_sla, conversation, sla_policy)
    check_resolution_time(applied_sla, conversation, sla_policy)
  end

  def check_first_response_time(applied_sla, conversation, sla_policy)
    return if conversation.resolved?
    return if sla_policy.first_response_time_threshold.blank?

    threshold = conversation.created_at.to_i + sla_policy.first_response_time_threshold.to_i
    # If first reply is present, compare it with threshold
    # else use current.time
    return if conversation.first_reply_created_at.present? && conversation.first_reply_created_at.to_i <= threshold
    return unless Time.now.to_i > threshold

    handle_missed_sla(applied_sla, conversation, sla_policy)
  end

  def check_next_response_time(applied_sla, conversation, sla_policy)
    return if conversation.resolved?
    unless sla_policy.next_response_time_threshold.present? && conversation.first_reply_created_at.present? && conversation.waiting_since.present?
      return
    end

    threshold = conversation.waiting_since.to_i + sla_policy.next_response_time_threshold
    return unless Time.now.to_i > threshold

    handle_missed_sla(applied_sla, conversation, sla_policy)
  end

  def check_resolution_time(applied_sla, conversation, sla_policy)
    return unless sla_policy.resolution_time_threshold.present? && conversation.resolved?

    threshold = sla_policy.resolution_time_threshold.to_i
    resolution_time = conversation.account.reporting_events.where(name: 'conversation_resolved').last.value

    if resolution_time > threshold
      handle_missed_sla(applied_sla, conversation, sla_policy)
    else
      handle_hit_sla(applied_sla, conversation, sla_policy)
    end
  end

  def handle_missed_sla(applied_sla, conversation, sla_policy)
    applied_sla.update(sla_status: 'missed')
    Rails.logger.warn "SLA missed for conversation #{conversation.id} in account #{conversation.account_id} for sla_policy #{sla_policy.id}"
  end

  def handle_hit_sla(applied_sla, conversation, sla_policy)
    applied_sla.update(sla_status: 'hit')
    Rails.logger.info "SLA hit for conversation #{conversation.id} in account #{conversation.account_id} for sla_policy #{sla_policy.id}"
  end
end
