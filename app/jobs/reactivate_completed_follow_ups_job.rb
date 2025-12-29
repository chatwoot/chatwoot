# frozen_string_literal: true

class ReactivateCompletedFollowUpsJob < ApplicationJob
  queue_as :scheduled_jobs

  BATCH_SIZE = 500

  def perform
    ConversationFollowUp
      .ready_to_reactivate
      .includes(
        lead_follow_up_sequence: {},
        conversation: [:messages, :labels]
      )
      .limit(BATCH_SIZE)
      .find_each(batch_size: 100) do |follow_up|
        process_follow_up(follow_up)
      rescue StandardError => e
        Rails.logger.error("Error reactivating follow_up #{follow_up.id}: #{e.message}")
        follow_up.clear_processing!
      end
  end

  private

  def process_follow_up(follow_up)
    follow_up.mark_processing!

    sequence = follow_up.lead_follow_up_sequence
    conversation = follow_up.conversation

    # Check if conversation matches reactivation filters
    unless sequence.matches_reactivation_filters?(conversation)
      Rails.logger.info(
        "Follow-up #{follow_up.id} skipped: conversation doesn't match filters. " \
        "Sequence: #{sequence.id}, Conversation: #{conversation.id}"
      )
      return follow_up.clear_processing!
    end

    # Use reorder instead of order to bypass Message's default_scope { order(created_at: :asc) }
    # which would interfere with getting the actual last message
    last_message = conversation.messages.reorder(created_at: :desc).first

    return follow_up.clear_processing! unless last_message&.outgoing?

    client_response = conversation.messages
                                  .where('created_at > ?', last_message.created_at)
                                  .where(message_type: :incoming)
                                  .exists?

    return follow_up.clear_processing! if client_response

    # Calculate next_action_at based on first step, from the last agent message time
    first_step = follow_up.lead_follow_up_sequence.enabled_steps.first
    next_action_at = if first_step && first_step['type'] == 'wait'
                       calculate_wait_time_from_message(first_step, last_message)
                     else
                       Time.current
                     end

    follow_up.update!(
      status: 'active',
      current_step: 0,
      next_action_at: next_action_at,
      processing_started_at: nil,
      completed_at: nil,
      metadata: (follow_up.metadata || {}).merge(
        reactivated_at: Time.current,
        reactivation_count: (follow_up.metadata&.dig('reactivation_count') || 0) + 1,
        last_agent_message_at: last_message.created_at
      )
    )

    # Schedule job for exact timing
    follow_up.schedule_job!

    Rails.logger.info("Reactivated follow_up #{follow_up.id} for conversation #{conversation.id}")
  end

  def calculate_wait_time_from_message(step, last_message)
    config = step['config']
    delay = config['delay_value'].to_i

    # Calculate total wait time in seconds
    total_wait_seconds = case config['delay_type']
                         when 'minutes'
                           delay.minutes
                         when 'hours'
                           delay.hours
                         when 'days'
                           delay.days
                         else
                           delay.hours
                         end

    # Calculate time elapsed since last agent message
    time_elapsed = Time.current - last_message.created_at

    # Calculate remaining time
    remaining_time = total_wait_seconds - time_elapsed

    # If time already elapsed or will elapse very soon, execute immediately
    # Otherwise schedule for the exact remaining time
    remaining_time <= 0 ? Time.current : Time.current + remaining_time
  end
end
