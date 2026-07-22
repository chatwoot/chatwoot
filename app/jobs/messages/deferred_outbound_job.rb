class Messages::DeferredOutboundJob < ApplicationJob
  queue_as :high

  def perform(conversation_id:, content: nil, blob_ids: nil, user_id: nil, automation_rule_id: nil)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    user = User.find_by(id: user_id) if user_id.present?

    if blob_ids.present?
      send_attachment(conversation, user, Array(blob_ids))
    else
      send_text(conversation, user, content, automation_rule_id)
    end
  end

  private

  def send_text(conversation, user, content, automation_rule_id)
    return if content.blank?

    params = { content: content, private: false }
    params[:content_attributes] = { automation_rule_id: automation_rule_id } if automation_rule_id.present?

    Messages::MessageBuilder.new(user, conversation, params).perform
  end

  def send_attachment(conversation, user, blob_ids)
    blobs = ActiveStorage::Blob.where(id: blob_ids)
    return if blobs.blank?

    helper = ActionService.new(conversation)
    params = helper.attachment_message_params(blobs)
    Messages::MessageBuilder.new(user, conversation, params).perform
  end
end
