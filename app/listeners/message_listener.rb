class MessageListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    return if message.nil?
    
    # Voice message delivery functionality has been removed for now
    # This would be where we'd handle delivering agent messages to voice calls
  end
  
  private
  
  def extract_message_and_account(event)
    message = event.data[:message]
    account = message.account
    [message, account]
  end
end