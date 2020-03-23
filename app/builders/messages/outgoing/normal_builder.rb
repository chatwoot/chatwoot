class Messages::Outgoing::NormalBuilder
  attr_reader :message

  def initialize(user, conversation, params)
    @content = params[:message]
    @private = params[:private] || false
    @conversation = conversation
    @user = user
    @fb_id = params[:fb_id]
    @content_type = params[:content_type]
    @items = params.to_unsafe_h&.dig(:content_attributes, :items)
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
      user_id: @user&.id,
      source_id: @fb_id,
      content_type: @content_type,
      items: @items
    }
  end
end
