module ScheduledMessageHandler
  extend ActiveSupport::Concern

  included do
    after_update_commit :update_scheduled_message_status, if: :should_update_scheduled_message?
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

  def dispatch_scheduled_message_update(scheduled_message)
    Rails.configuration.dispatcher.dispatch(
      Events::Types::SCHEDULED_MESSAGE_UPDATED,
      Time.zone.now,
      scheduled_message: scheduled_message
    )
  end
end
