class EnrollEligibleConversationsJob < ApplicationJob
  queue_as :default

  # Process in batches to avoid memory issues with millions of conversations
  BATCH_SIZE = 500

  def perform(sequence_id)
    sequence = LeadFollowUpSequence.find_by(id: sequence_id)
    return unless sequence&.active?

    first_step = sequence.enabled_steps.first
    unless first_step
      Rails.logger.warn "Sequence #{sequence.id} has no enabled steps, skipping enrollment"
      return
    end

    Rails.logger.info "Auto-enrolling conversations for sequence #{sequence.id} (#{sequence.name})"

    enrolled_count = 0
    skipped_count = 0
    start_time = Time.current

    conversations = build_eligible_conversations_query(sequence)
    Rails.logger.info "Found #{conversations.count} eligible conversations for sequence #{sequence.id}"
    conversations.in_batches(of: BATCH_SIZE) do |batch|
      if sequence.settings.dig('stop_on_contact_reply')
        batch = filter_by_last_message(batch)
      end

      batch.each do |conversation|
        enroll_conversation(conversation, sequence, first_step)
        enrolled_count += 1
      rescue StandardError => e
        Rails.logger.error "Failed to enroll conversation #{conversation.id}: #{e.message}"
        Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}" if e.backtrace
        # Si es un error de validación, mostrar detalles
        if e.respond_to?(:record) && e.record&.errors&.any?
          Rails.logger.error "Validation errors: #{e.record.errors.full_messages.join(', ')}"
        end
        skipped_count += 1
      end

      Rails.logger.debug "Processed batch: #{enrolled_count} enrolled, #{skipped_count} skipped"
    end

    duration = Time.current - start_time
    Rails.logger.info "Auto-enrollment complete for sequence #{sequence.id} in #{duration.round(2)}s: " \
                      "Enrolled: #{enrolled_count}, Skipped: #{skipped_count}"
  end

  private

  def build_eligible_conversations_query(sequence)
    # Leer include_completed de trigger_conditions, default a true para backward compatibility
    include_completed = sequence.trigger_conditions.dig('enrollment_filter', 'include_completed')
    include_completed = true if include_completed.nil?

    query = LeadRetargeting::EligibleConversationsQueryBuilder.call(
      account_id: sequence.account_id,
      inbox_id: sequence.inbox_id,
      trigger_conditions: sequence.trigger_conditions,
      include_cancelled: true,
      include_completed: include_completed,
      stop_on_contact_reply: false
    )

    Rails.logger.info "Found #{query.count} eligible conversations for sequence #{sequence.id}"
    query
  end

  def filter_by_last_message(batch)
    conversation_ids = batch.pluck(:id)
    return batch if conversation_ids.empty?

    valid_conversation_ids = Conversation
                             .where(id: conversation_ids)
                             .where(
                               'conversations.id NOT IN (
                                 SELECT DISTINCT m1.conversation_id
                                 FROM messages m1
                                 WHERE m1.conversation_id IN (?)
                                   AND m1.message_type = 0
                                   AND m1.message_type != 2
                                   AND m1.created_at = (
                                     SELECT MAX(m2.created_at)
                                     FROM messages m2
                                     WHERE m2.conversation_id = m1.conversation_id
                                       AND m2.message_type != 2
                                   )
                               )',
                               conversation_ids
                             )
                             .pluck(:id)

    batch.where(id: valid_conversation_ids)
  end

  def enroll_conversation(conversation, sequence, first_step)
    existing_follow_up = conversation.conversation_follow_up

    # Calculate re-enrollment logic
    re_enrollment_count = conversation.sequence_enrollments
                                     .where(lead_follow_up_sequence: sequence)
                                     .count

    # Create new enrollment session
    enrollment = SequenceEnrollment.create!(
      conversation: conversation,
      lead_follow_up_sequence: sequence,
      enrolled_at: Time.current,
      status: 'active',
      current_step: 0,
      metadata: {
        enrolled_via: 'auto_enroll_on_sequence_activation',
        re_enrollment_count: re_enrollment_count
      }
    )

    # Calculate next action time
    next_action_at = if first_step['type'] == 'wait'
                       if existing_follow_up && %w[cancelled completed failed].include?(existing_follow_up.status)
                         calculate_wait_time_from_now(first_step)
                       else
                         calculate_wait_time(conversation, first_step)
                       end
                     else
                       Time.current
                     end

    # Si existe un follow-up previo, actualizarlo. Si no, crear uno nuevo.
    follow_up = existing_follow_up || conversation.build_conversation_follow_up

    follow_up.update!(
      lead_follow_up_sequence: sequence,
      sequence_enrollment: enrollment,
      current_step: 0,
      next_action_at: next_action_at,
      status: 'active',
      completed_at: nil,
      processing_started_at: nil,
      metadata: (follow_up.metadata || {}).merge({
        last_enrolled_at: Time.current,
        re_enrollment_count: re_enrollment_count,
        last_enrollment_via: 'auto_enroll_on_sequence_activation'
      })
    )

    # Create enrollment event
    enrollment.create_event(
      event_type: 'enrolled',
      metadata: {
        source: 'auto_enroll_on_sequence_activation',
        re_enrollment: re_enrollment_count > 0
      }
    )

    follow_up.schedule_job!
    Rails.logger.info "Enrolled conversation #{conversation.id} in sequence #{sequence.id} (Enrollment: #{enrollment.id})"
  end

  def calculate_wait_time(conversation, step)
    return Time.current unless step['type'] == 'wait'

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

  def calculate_wait_time_from_now(step)
    return Time.current unless step['type'] == 'wait'

    config = step['config']
    delay = config['delay_value'].to_i

    # Para re-enrollments, usar Time.current como base
    # Esto asegura que la secuencia comience desde cero
    case config['delay_type']
    when 'minutes'
      Time.current + delay.minutes
    when 'hours'
      Time.current + delay.hours
    when 'days'
      Time.current + delay.days
    else
      Time.current + delay.hours
    end
  end
end
