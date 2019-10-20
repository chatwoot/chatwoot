class MessageFinder
  def initialize(conversation, params)
    @conversation = conversation
    @params = params
  end

  def perform
    current_messages
  end

  private

  def current_messages
    if @params[:before].present?
      @conversation.messages.reorder('created_at desc').where('id < ?', @params[:before]).limit(20).reverse
    else
      @conversation.messages.reorder('created_at desc').limit(20).reverse
    end
  end
end
