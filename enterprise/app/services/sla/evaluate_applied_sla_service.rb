class Sla::EvaluateAppliedSlaService
  pattr_initialize [:applied_sla!]

  def perform
    check_sla_thresholds

    # We will calculate again in the next iteration
    return unless applied_sla.conversation.resolved?

    # No SLA missed, so marking as hit as conversation is resolved
    handle_hit_sla(applied_sla) if applied_sla.active?
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

    # Determine if a next_response_time event has already been recorded for the current message
    last_customer_message_id = conversation.messages.where(message_type: :incoming).last&.id
    already_missed = applied_sla.sla_events.exists?(event_type: :nrt, meta: { message_time: last_customer_message_id })

    return if already_missed || still_within_threshold?(threshold)

    meta = { message_id: last_customer_message_id }

    handle_missed_sla(applied_sla, 'nrt', meta)
  end

  def check_resolution_time_threshold(applied_sla, conversation, sla_policy)
    return if conversation.resolved?

    threshold = conversation.created_at.to_i + sla_policy.resolution_time_threshold.to_i
    return if still_within_threshold?(threshold)

    handle_missed_sla(applied_sla, 'rt')
  end

  def handle_missed_sla(applied_sla, type, meta = {})
    return unless applied_sla.active?

    return if SlaEvent.exists?(applied_sla: applied_sla, event_type: type, meta: meta)

    create_sla_event(applied_sla, type, meta)
    Rails.logger.warn "SLA #{type} missed for conversation #{applied_sla.conversation.id} " \
                      "in account #{applied_sla.account_id} " \
                      "for sla_policy #{applied_sla.sla_policy.id}"

    # applied_sla.update!(sla_status: 'missed')
  end

  def handle_hit_sla(applied_sla)
    return unless applied_sla.active?

    applied_sla.update!(sla_status: 'hit')
    Rails.logger.info "SLA hit for conversation #{applied_sla.conversation.id} " \
                      "in account #{applied_sla.account_id} " \
                      "for sla_policy #{applied_sla.sla_policy.id}"
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
end
