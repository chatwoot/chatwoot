module ScheduledMessageHandler
  extend ActiveSupport::Concern

  included do
    after_update_commit :update_scheduled_message_status, if: :should_update_scheduled_message?
    after_create_commit :hold_pending_scheduled_messages, if: :should_hold_scheduled_messages?
  end

  private

  def should_update_scheduled_message?
    saved_change_to_status? && scheduled_message_id.present?
  end

  def scheduled_message_id
    additional_attributes&.dig('scheduled_message_id')
  end

  def update_scheduled_message_status
    scheduled_message = conversation.scheduled_messages.find_by(id: scheduled_message_id)
    return unless scheduled_message

    new_status = determine_scheduled_message_status
    return unless new_status
    return if scheduled_message.status == new_status.to_s

    scheduled_message.update!(status: new_status)
    dispatch_scheduled_message_update(scheduled_message)
  end

  def determine_scheduled_message_status
    case status
    when 'delivered', 'read'
      :sent
    when 'failed'
      :failed
    end
  end

  def should_hold_scheduled_messages?
    incoming? && !private? && !reaction?
  end

  def hold_pending_scheduled_messages
    cutoff = created_at || Time.current
    conversation.scheduled_messages
                .pending
                .where(hold_on_reply: true)
                .where('scheduled_at > ?', cutoff)
                .find_each do |sm|
      sm.update!(status: :held)
      advance_recurring_series(sm) if sm.recurring_scheduled_message_id.present?
      dispatch_scheduled_message_update(sm)
    end
  end

  def advance_recurring_series(scheduled_message)
    recurring = scheduled_message.recurring_scheduled_message
    return unless recurring&.active?

    RecurringScheduledMessages::CreateNextOccurrenceService.new(
      recurring_scheduled_message: recurring,
      previous_scheduled_message: scheduled_message,
      skip_increment: true
    ).perform

    # Detach from the series so the agent can reschedule/resend without advancing it again
    scheduled_message.update_column(:recurring_scheduled_message_id, nil) # rubocop:disable Rails/SkipsModelValidations
  end

  def dispatch_scheduled_message_update(scheduled_message)
    Rails.configuration.dispatcher.dispatch(
      Events::Types::SCHEDULED_MESSAGE_UPDATED,
      Time.zone.now,
      scheduled_message: scheduled_message
    )
  end
end
