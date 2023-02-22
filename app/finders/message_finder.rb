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

  def current_messages
    limit = @params[:limit] or 20

    if @params[:after].present?
      messages.reorder('created_at asc').where('id >= ?', @params[:before].to_i).limit(limit)
    elsif @params[:before].present?
      messages.reorder('created_at desc').where('id < ?', @params[:before].to_i).limit(limit).reverse
    else
      messages.reorder('created_at desc').limit(limit).reverse
    end
  end
end
