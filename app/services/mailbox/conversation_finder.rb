class Mailbox::ConversationFinder
  DEFAULT_STRATEGIES = [
    Mailbox::ConversationFinderStrategies::ReceiverUuidStrategy,
    Mailbox::ConversationFinderStrategies::InReplyToStrategy,
    Mailbox::ConversationFinderStrategies::ReferencesStrategy,
    Mailbox::ConversationFinderStrategies::NewConversationStrategy
  ].freeze

  def initialize(mail, strategies: DEFAULT_STRATEGIES)
    @mail = mail
    @strategies = strategies
  end

  def find
    @strategies.each do |strategy_class|
      conversation = strategy_class.new(@mail).find

      next unless conversation

      strategy_name = strategy_class.name.demodulize.underscore
      Rails.logger.info "Conversation found via #{strategy_name} strategy"
      return conversation
    end

    # Should not reach here if NewConversationStrategy is in the chain
    Rails.logger.error 'No conversation found via any strategy (NewConversationStrategy missing?)'
    nil
  end
end
