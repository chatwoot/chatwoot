class Conversations::ActivityMessageJob < ApplicationJob
  queue_as :high

  def perform(conversation, message_params, user_id = nil)
    # Check if the same activity message was created recently (within 30 seconds)
    # This prevents duplicate activity messages when multiple saves trigger the same job
    existing_message = conversation.messages.activity.where(
      content: message_params[:content]
    ).where('created_at > ?', 30.seconds.ago).first

    return if existing_message.present?

    # Set Current.user if user_id was provided
    # This makes the user context available for hooks (like CSAT creation)
    if user_id.present?
      user = User.find_by(id: user_id)
      Current.user = user if user.present?
    end

    conversation.messages.create!(message_params)
  ensure
    # Clear Current.user after job completes
    Current.user = nil
  end
end
