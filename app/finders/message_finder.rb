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
    @conversation.messages.includes(:attachments, :sender)
  end

  def messages
    return conversation_messages if @params[:filter_internal_messages].blank?

    conversation_messages.where.not('private = ? OR message_type = ?', true, 2)
  end

  def current_messages
    if @params[:before].present?
      messages.reorder('created_at desc').where('id < ?', @params[:before]).limit(20).reverse
    else
      messages.reorder('created_at desc').limit(20).reverse
    end
  end
end
