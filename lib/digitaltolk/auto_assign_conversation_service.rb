class Digitaltolk::AutoAssignConversationService
  attr_accessor :accounts, :account

  def initialize
    @accounts = Account.all
  end

  def perform
    @accounts.each do |acc|
      @account = acc
      auto_assign!
    end
  end

  private

  def auto_assign!
    Rails.logger.warn "unassigned-left: #{unassigned_conversations.count}"
    unassigned_conversations.limit(30).each do |convo|
      convo.auto_assign_to_latest_agent
      Rails.logger.warn "auto-assigned: #{convo.display_id}"
    end
  end

  def unassigned_conversations
    account.conversations
           .attended
           .unassigned
           .where(id: Message.where.not(sender_id: nil).outgoing.select(:conversation_id))
  end
end
