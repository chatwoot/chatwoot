class Messages::Outgoing::NormalBuilder
  attr_reader :message

  def initialize(user, conversation, params)
    @content = params[:message]
    @private = ['1', 'true', 1].include? params[:private]
    @conversation = conversation
    @user = user
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
      user_id: @user.id,
      fb_id: @fb_id
    }
  end
end
