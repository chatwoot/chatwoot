class Conversations::ActivityMessageJob < ApplicationJob
  queue_as :high

  def perform(conversation, message_params)
    # Check if the same activity message was created recently (within 30 seconds)
    # This prevents duplicate activity messages when multiple saves trigger the same job
    existing_message = conversation.messages.activity.where(
      content: message_params[:content]
    ).where('created_at > ?', 30.seconds.ago).first

    return if existing_message.present?

    conversation.messages.create!(message_params)
  end
end
