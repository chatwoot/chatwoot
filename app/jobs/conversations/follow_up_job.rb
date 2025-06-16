class Conversations::FollowUpJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, follow_up_number)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.nil?

    last_message = conversation.messages
                               .not_activity
                               .not_template
                               .unscoped
                               .order(created_at: :desc).first
    return if last_message.incoming?

    # Get follow-up message content from Stark API
    stark_response = Stark::FollowUpService.new(conversation, follow_up_number).get_follow_up_content
    return if stark_response.nil?

    # Create follow-up message with content from Stark
    case follow_up_number
    when 1
      create_follow_up_message(conversation, 1, stark_response)
      # Schedule Follow-up 2 (if still no reply in 23h)
      jid = Conversations::FollowUpJob.set(wait: 24.hours).perform_later(conversation.id, 2)
      conversation.update!(follow_up_jid: jid)

    when 2
      create_follow_up_message(conversation, 2, stark_response)
    end
  end

  private

  def create_follow_up_message(conversation, follow_up_number, content)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: content,
      content_attributes: {
        follow_up: true,
        follow_up_number: follow_up_number
      }
    )
  end
end
