class MessageListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    return if message.nil?
    
    if message.conversation.inbox.channel.class.name == 'Channel::Voice'
      # Deliver the message to voice call if it's a voice channel
      Voice::MessageDeliveryService.new(message).perform
    end
  end
  
  private
  
  def extract_message_and_account(event)
    message = event.data[:message]
    account = message.account
    [message, account]
  end
end