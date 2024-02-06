class Digitaltolk::AddMessageService
  attr_accessor :sender, :conversation, :content, :is_incoming

  def initialize(sender, conversation, content)
    @conversation = conversation
    @content = content
    @sender = sender
    @is_incoming = is_incoming
  end

  def perform
    return unless @conversation.present?

    create_message
  end

  private

  def create_message
    return unless content.present?

    Messages::MessageBuilder.new(sender, @conversation, message_params).perform 
  end

  def message_type
    'outgoing'
  end

  def message_params
    {
      message_type: message_type,
      content: content
    }
  end
end