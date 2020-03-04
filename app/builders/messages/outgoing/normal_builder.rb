class Messages::Outgoing::NormalBuilder
  attr_reader :message

  def initialize(sender, conversation, params)
    @content = params[:message]
    @private = params[:private]
    @conversation = conversation
    @sender = sender
    @fb_id = params[:fb_id]
  end

  def perform
    @message = @conversation.messages.create!(message_params)
  end

  private

  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: @content,
      private: @private,
      sender: @sender,
      user_id: @sender.id,
      source_id: @fb_id
    }
  end
end
