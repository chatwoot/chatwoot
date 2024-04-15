class Migration::FixInvalidEmailsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    webflow_email = '{{email}}@loopia.invalid'
    messages = Message.where("content_attributes::text LIKE '%#{webflow_email}%'")
    conversations = Conversation.where(id: messages.pluck(:conversation_id).uniq)

    Rails.logger.warn "fixingconversation: #{conversations.count}, #{messages.count}"
    conversations.each do |conversation|
      Digitaltolk::FixInvalidConversation.new(conversation).call
    end
  end
end
