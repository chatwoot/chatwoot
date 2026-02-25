class Mailbox::ConversationFinderStrategies::BaseStrategy
  attr_reader :mail

  def initialize(mail)
    @mail = mail
  end

  # Returns Conversation or nil
  # Subclasses must implement this method
  def find
    raise NotImplementedError, "#{self.class} must implement #find"
  end
end
