class Voice::CallMessageBuilder
  def initialize(call)
    @call = call
  end

  def perform!
    call.message || create_message!
  end

  private

  attr_reader :call

  def create_message!
    params = {
      content: 'Voice Call',
      message_type: call.outgoing? ? 'outgoing' : 'incoming',
      content_type: 'voice_call'
    }
    Messages::MessageBuilder.new(sender, call.conversation, params).perform
  end

  def sender
    call.outgoing? ? call.accepted_by_agent : call.contact
  end
end
