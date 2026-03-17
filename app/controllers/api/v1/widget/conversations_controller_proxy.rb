module Api::V1::Widget::ConversationsControllerProxy
  def create
    super
    mirror_message_to_linked(conversation)
  end

  def update
    super
    mirror_message_to_linked(conversation)
  end

  private

  def mirror_message_to_linked(conv)
    return if conv.blank?
    return if params[:message].blank?

    Widget::ConversationProxyService.new(conv, params[:message]).mirror_incoming_from_widget
  end
end
