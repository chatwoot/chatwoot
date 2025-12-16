class Sla::EvaluateAppliedSlaService
  pattr_initialize [:applied_sla!]
  include ReportingEventHelper

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

  def should_use_business_hours?(sla_policy, inbox)
    sla_policy.only_during_business_hours? && inbox.working_hours_enabled?
  end

  # Calculates the SLA threshold deadline considering business hours if enabled.
  #
  # This method determines when an SLA will be breached by adding the threshold duration
  # to the start time. If business hours are enabled, it only counts time during working hours,
  # automatically skipping weekends and after-hours periods.
  def calculate_threshold_deadline(start_time, threshold_seconds, inbox, sla_policy)
    # Fall back to simple calendar time calculation if business hours not enabled
    return start_time.to_i + threshold_seconds unless should_use_business_hours?(sla_policy, inbox)

    # Configure the working_hours gem with inbox-specific schedule and timezone
    configure_working_hours_for_calculation(inbox)

    # Convert start time to inbox timezone for accurate business hours calculation
    start_time_in_timezone = start_time.in_time_zone(inbox.timezone).to_time

    # Determine effective start time: if outside business hours, advance to next working time
    # Example: Saturday 6 PM conversation would start counting Monday 9 AM
    effective_start_time = if start_time_in_timezone.in_working_hours?
                             start_time_in_timezone
                           else
                             WorkingHours.next_working_time(start_time_in_timezone)
                           end

    # Add working time duration
    # This automatically skips non-working hours, weekends, and holidays
    deadline = effective_start_time + threshold_seconds.working.seconds
    deadline.to_i
  end

  def configure_working_hours_for_calculation(inbox)
    inbox_working_hours = configure_working_hours(inbox.working_hours)
    return if inbox_working_hours.blank?

    WorkingHours::Config.working_hours = inbox_working_hours
    WorkingHours::Config.time_zone = inbox.timezone
  end

  def still_within_threshold?(threshold)
    Time.zone.now.to_i < threshold
  end

  def check_first_response_time_threshold(applied_sla, conversation, sla_policy)
    threshold = calculate_threshold_deadline(
      conversation.created_at,
      sla_policy.first_response_time_threshold.to_i,
      conversation.inbox,
      sla_policy
    )
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

    threshold = calculate_threshold_deadline(
      conversation.waiting_since,
      sla_policy.next_response_time_threshold.to_i,
      conversation.inbox,
      sla_policy
    )
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

    threshold = calculate_threshold_deadline(
      conversation.created_at,
      sla_policy.resolution_time_threshold.to_i,
      conversation.inbox,
      sla_policy
    )
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
