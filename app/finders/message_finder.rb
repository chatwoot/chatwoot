class MessageFinder
  def initialize(conversation, params)
    @conversation = conversation
    @params = params
  end

  def perform
    current_messages
  end

  private

  def conversation_messages
    @conversation.messages.includes(:attachments, :sender, sender: { avatar_attachment: [:blob] })
  end

  def messages
    return conversation_messages if @params[:filter_internal_messages].blank?

    conversation_messages.where.not('private = ? OR message_type = ?', true, 2)
  end

  def messages_in_desc_order
    messages.reorder('created_at desc')
  end

  def current_messages
    messages_to_display = messages_in_desc_order

    if @params[:before].present?
      messages_to_display = messages_to_display.where('id < ?', @params[:before].to_i)

      if @params[:after].present? && @params[:after].to_i < @params[:before].to_i - 25
        messages_to_display = messages_to_display.where('id >= ?', @params[:after].to_i)
        return messages_to_display.reverse
      end
    end

    messages_to_display.limit(20).reverse
  end
end
