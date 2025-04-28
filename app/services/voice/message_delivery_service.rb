module Voice
  class MessageDeliveryService
  # This service will handle delivering messages from agents to active voice calls
  # For now we'll store the messages in Redis with the call_sid as the key
  # This way the TwiML controller can retrieve and read them out to the caller

  attr_reader :message, :conversation
  
  def initialize(message)
    @message = message
    @conversation = message.conversation
  end
  
  def perform
    return unless should_deliver_message?
    
    call_sid = conversation.additional_attributes&.dig('call_sid')
    return unless call_sid.present?
    
    # Store the message in Redis to be read out in the next TwiML request
    redis_key = "voice_message:#{call_sid}"
    
    # Add the message to a Redis list
    Redis::Alfred.lpush(redis_key, { 
      content: message.content,
      message_id: message.id,
      delivered: false
    }.to_json)
    
    # Set expiration so we don't keep messages forever
    Redis::Alfred.expire(redis_key, 1.hour.to_i)
    
    # Update the message with delivery status
    update_message_delivery_status
  end
  
  private
  
  def should_deliver_message?
    # Only deliver outgoing messages (from agents)
    return false unless message.outgoing?
    
    # Only deliver text messages, not attachments etc
    return false unless message.content.present?
    
    # Only deliver to active voice calls
    return false unless conversation.additional_attributes&.dig('call_sid').present?
    return false unless conversation.additional_attributes&.dig('call_status') == 'in-progress'
    
    true
  end
  
  def update_message_delivery_status
    additional_attributes = message.additional_attributes || {}
    additional_attributes[:voice_delivery_status] = 'queued'
    message.update(additional_attributes: additional_attributes)
  end
  end
end