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
    if @params[:after].present?
      messages.reorder('created_at asc').where('id >= ?', @params[:after].to_i)
    elsif @params[:before].present?
      messages.reorder('created_at desc').where('id < ?', @params[:before].to_i).limit(20).reverse
    else
      messages.reorder('created_at desc').limit(20).reverse
    end

    messages_to_display.limit(20).reverse
  end
end
