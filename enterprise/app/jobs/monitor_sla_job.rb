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
    return unless sla_policy.first_response_time_threshold.present? && conversation.first_response_time.present?

    threshold = conversation.created_at.to_i + sla_policy.first_response_time_threshold
    return unless conversation.first_response_time.to_i > threshold

    handle_missed_sla(applied_sla, conversation, sla_policy)
  end

  def check_next_response_time(applied_sla, conversation, sla_policy)
    return unless sla_policy.next_response_time_threshold.present? && conversation.waiting_since.present?

    threshold = conversation.waiting_since.to_i + sla_policy.next_response_time_threshold
    return unless Time.now.to_i > threshold

    handle_missed_sla(applied_sla, conversation, sla_policy)
  end

  def check_resolution_time(applied_sla, conversation, sla_policy)
    return unless sla_policy.resolution_time_threshold.present? && conversation.status.resolved?

    threshold = conversation.created_at.to_i + sla_policy.resolution_time_threshold
    resolution_time = conversation.reporting_events.where(name: 'conversation_resolved').first.value

    return unless resolution_time > threshold

    handle_missed_sla(applied_sla, conversation, sla_policy)
  end

  def handle_missed_sla(applied_sla, conversation, sla_policy)
    applied_sla.update(sla_status: 'missed')
    Rails.logger.warn "SLA missed for conversation #{conversation.id} in account #{conversation.account_id} for sla_policy #{sla_policy.id}"
  end
end
