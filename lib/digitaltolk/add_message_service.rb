class Digitaltolk::AddMessageService
  attr_accessor :sender, :conversation, :content, :is_incoming

  def initialize(sender, conversation, content)
    @conversation = conversation
    @content = content
    @sender = sender
    @is_incoming = is_incoming
  end

  def perform
    return if @conversation.blank?
    return if content.blank?

    message = create_message
    schedule_formatting(message)
    message
  end

  private

  def create_message
    Messages::MessageBuilder.new(sender, @conversation, message_params).perform
  end

  def schedule_formatting(message)
    return unless message

    Digitaltolk::FormatOutgoingEmailJob.perform_async(message.id)
  end

  def message_type
    'outgoing'
  end

  def message_params
    {
      message_type: message_type,
      content: ReverseMarkdown.convert(content)
    }
  end
end
