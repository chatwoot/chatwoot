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
    query = LeadRetargeting::EligibleConversationsQueryBuilder.call(
      account_id: sequence.account_id,
      inbox_id: sequence.inbox_id,
      trigger_conditions: sequence.trigger_conditions,
      include_cancelled: true,
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
    if existing_follow_up&.status == 'cancelled'
      existing_follow_up.destroy
      Rails.logger.info "Removed cancelled follow-up #{existing_follow_up.id} for conversation #{conversation.id}"
    end

    next_action_at = if first_step['type'] == 'wait'
                       calculate_wait_time(first_step)
                     else
                       Time.current
                     end

    follow_up = ConversationFollowUp.create!(
      conversation: conversation,
      lead_follow_up_sequence: sequence,
      current_step: 0,
      next_action_at: next_action_at,
      status: 'active',
      metadata: {
        enrolled_at: Time.current,
        enrolled_via: 'auto_enroll_on_sequence_activation'
      }
    )

    follow_up.schedule_job!
  end

  def calculate_wait_time(step)
    return Time.current unless step['type'] == 'wait'

    config = step['config']
    delay = config['delay_value'].to_i

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
