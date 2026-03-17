module Api::V1::Widget::MessagesControllerProxy
  def create
    super
    mirror_message_to_linked
  end

  private

  def mirror_message_to_linked
    return if conversation.blank?
    return if @message.blank?

    attachment_ids = @message.attachments.pluck(:id)

    Widget::ConversationProxyService.new(
      conversation,
      {
        content: @message.content,
        echo_id: params.dig(:message, :echo_id),
        attachment_ids: attachment_ids
      }
    ).mirror_incoming_from_widget
  end
end
