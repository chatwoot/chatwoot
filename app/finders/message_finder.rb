class MessageFinder
  def initialize(conversation, params)
    @conversation = conversation
    @params = params
  end

  def perform
    current_messages
  end

  private

  def messages
    return @conversation.messages if @params[:filter_internal_messages].blank?

    @conversation.messages.where.not('private = ? OR message_type = ?', true, 2)
  end

  def current_messages
    if @params[:before].present?
      messages.reorder('created_at desc').where('id < ?', @params[:before]).limit(20).reverse
    else
      messages.reorder('created_at desc').limit(20).reverse
    end
  end
end
