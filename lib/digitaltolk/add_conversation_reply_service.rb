class Digitaltolk::AddConversationReplyService
  attr_accessor :params, :conversation

  def initialize(conversation, params)
    @conversation = conversation
    @params = params
  end

  def perform
    create_message
    result_data
  end

  private

  def create_message
    @message = @conversation.messages.build(message_params)
    @message.save!
    @message
  end

  def result_data
    {
      success: @message.persisted?,
    }.merge(error_data).merge(success_data)
  end

  def error_data
    return {} if @message.valid?

    {
      errors: @message.errors
    }
  end

  def success_data
    return {} unless @message.valid?

    {
      message: @message
    }
  end

  def message_params
    {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type,
      content: @params[:content],
      private: false,
      sender: sender,
      content_type: content_type,
      customized: true
    }
  end

  def message_type
    'incoming'
  end

  def content_type
    'text'
  end

  def sender
    @conversation.contact
  end
end