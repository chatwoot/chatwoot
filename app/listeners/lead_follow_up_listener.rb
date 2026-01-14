class LeadFollowUpListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation
    follow_up = conversation.conversation_follow_up

    return unless follow_up

    if message.incoming?
      pause_sequence_on_contact_reply(follow_up)
    elsif message.outgoing? && message.sender.is_a?(User)
      reset_sequence_on_agent_reply(follow_up)
    end
  end

  private

  def pause_sequence_on_contact_reply(follow_up)
    return unless follow_up.status == 'active'

    if follow_up.lead_follow_up_sequence.settings.dig('stop_on_contact_reply')
      follow_up.cancel_job!
      follow_up.mark_as_completed!('Contact replied')
      Rails.logger.info "Completed follow-up #{follow_up.id} - contact replied"
    end
  end

  def reset_sequence_on_agent_reply(follow_up)
    return unless follow_up.status == 'active'

    first_step = follow_up.lead_follow_up_sequence.enabled_steps.first
    return unless first_step

    conversation = follow_up.conversation

    next_action_at = if first_step['type'] == 'wait'
                       calculate_wait_time(conversation, first_step)
                     else
                       Time.current
                     end

    follow_up.update!(
      current_step: 0,
      next_action_at: next_action_at,
      metadata: (follow_up.metadata || {}).merge(
        reset_at: Time.current,
        reset_count: (follow_up.metadata&.dig('reset_count') || 0) + 1,
        base_time: conversation.last_chat_message_at
      )
    )

    # Reschedule job for the new next_action_at
    follow_up.schedule_job!

    Rails.logger.info "Reset follow-up #{follow_up.id} - agent replied"
  end

  def calculate_wait_time(conversation, step)
    config = step['config']
    delay = config['delay_value'].to_i

    # Usar last_chat_message_at como base (excluye mensajes de actividad)
    base_time = conversation.last_chat_message_at

    calculated_time = case config['delay_type']
                      when 'minutes'
                        base_time + delay.minutes
                      when 'hours'
                        base_time + delay.hours
                      when 'days'
                        base_time + delay.days
                      else
                        base_time + delay.hours
                      end

    # Si el tiempo calculado ya pasó, ejecutar inmediatamente
    [calculated_time, Time.current].max
  end
end
