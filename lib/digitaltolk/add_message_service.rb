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

    Digitaltolk::FormatOutgoingEmailJob.perform_later(message.id)
  end

  def message_type
    'outgoing'
  end

  def message_params
    {
      message_type: message_type,
      content: content_with_signature
    }
  end

  def content_with_signature
    return reversed_markdown_content if message_signature.blank?

    [reversed_markdown_content, message_signature].compact.join("\n\n")
  end

  def reversed_markdown_content
    ReverseMarkdown.convert(content)
  end

  def message_signature
    sender&.message_signature
  end
end
