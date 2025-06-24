class Messages::Instagram::CommentMessageBuilder < Messages::Instagram::BaseMessageBuilder
  def initialize(message, inbox)
    @message = message
    @inbox = inbox
    @contact_inbox = inbox.contact_inboxes.where(source_id: sender_id).last
  end

  def perform
    return if @inbox.channel.reauthorization_required?
    return if message_existed?

    ActiveRecord::Base.transaction do
      build_activity_message
      build_comment_message
    end
  end

  private

  def sender_id
    @message.dig(:from, :id)
  end

  def message_existed?
    Message.exists?(source_id: @message[:id], message_type: :incoming)
  end

  def build_activity_message
    Messages::Instagram::CommentActivityMessageBuilder.new(@message, conversation, @inbox).perform
  end

  def build_comment_message
    @message = conversation.messages.create!(message_params)
  end

  def message_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :incoming,
      content: @message[:text],
      source_id: @message[:id],
      sender: @contact_inbox.contact
    }
  end
end
