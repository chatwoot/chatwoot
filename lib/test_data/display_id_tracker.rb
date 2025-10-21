class TestData::DisplayIdTracker
  attr_reader :current

  def initialize(account:)
    max_display_id = Conversation.where(account_id: account.id).maximum(:display_id) || 0
    @current = max_display_id
  end

  def next_id
    @current += 1
  end
end
