class Sla::EvaluateAppliedSlaService
  pattr_initialize [:applied_sla!]
  include ReportingEventHelper

  def perform
    configure_business_hours_if_needed(applied_sla.conversation.inbox, applied_sla.sla_policy)
    check_sla_thresholds

    # We will calculate again in the next iteration
    return unless applied_sla.conversation.resolved?

    # after conversation is resolved, we will check if the SLA was hit or missed
    handle_hit_sla(applied_sla)
  end

  private

  def configure_business_hours_if_needed(inbox, sla_policy)
    if should_apply_business_hours?(inbox, sla_policy)
      @business_hours_configured = true
      configure_business_hours(inbox)
    else
      @business_hours_configured = false
    end
  end

  def should_apply_business_hours?(inbox, sla_policy)
    inbox.working_hours_enabled && sla_policy.only_during_business_hours
  end

  def configure_business_hours(inbox)
    inbox_working_hours = configure_working_hours(inbox.working_hours)
    return if inbox_working_hours.blank?

    WorkingHours::Config.working_hours = inbox_working_hours
    WorkingHours::Config.time_zone = inbox.timezone
    Time.zone = inbox.timezone
  end

  def check_sla_thresholds
    [:first_response_time_threshold, :next_response_time_threshold, :resolution_time_threshold].each do |threshold|
      next if applied_sla.sla_policy.send(threshold).blank?

      send("check_#{threshold}", applied_sla, applied_sla.conversation, applied_sla.sla_policy)
    end
  end

  def still_within_threshold?(threshold)
    Time.zone.now.to_i < threshold
  end

  def calculate_threshold(start_time, threshold_seconds)
    if @business_hours_configured
      if start_time.in_working_hours?
        start_time.to_i + threshold_seconds.working.seconds
      else
        (WorkingHours.next_working_time(start_time) + threshold_seconds.working.seconds).to_i
      end
    else
      start_time.to_i + threshold_seconds
    end
  end

  def check_first_response_time_threshold(applied_sla, conversation, sla_policy)
    threshold = calculate_threshold(conversation.created_at, sla_policy.first_response_time_threshold.to_i)

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

    threshold = calculate_threshold(conversation.waiting_since, sla_policy.next_response_time_threshold.to_i)

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

    threshold = calculate_threshold(conversation.created_at, sla_policy.resolution_time_threshold.to_i)

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
  end

  def handle_hit_sla(applied_sla)
    if applied_sla.active?
      applied_sla.update!(sla_status: 'hit')
      Rails.logger.info "SLA hit for conversation #{applied_sla.conversation.id} " \
                        "in account #{applied_sla.account_id} " \
                        "for sla_policy #{applied_sla.sla_policy.id}"
    else
      applied_sla.update!(sla_status: 'missed')
      Rails.logger.info "SLA missed for conversation #{applied_sla.conversation.id} " \
                        "in account #{applied_sla.account_id} " \
                        "for sla_policy #{applied_sla.sla_policy.id}"
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
end
