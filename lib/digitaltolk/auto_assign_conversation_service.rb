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
    Rails.logger.warn "unassigned-left: #{unassigned_csats.count}"
    unassigned_conversations.limit(20).each(&:auto_assign_to_latest_agent)

    unassigned_csats.limit(20).each do |csat|
      csat.update_column(:assigned_agent_id, csat.conversation.assignee_id)
    end
  end

  def unassigned_conversations
    account.conversations
           .attended
           .unassigned
           .where(id: Message.where.not(sender_id: nil).outgoing.select(:conversation_id))
  end

  def unassigned_csats
    account.csat_survey_responses
           .where(assigned_agent_id: nil)
           .joins(:conversation).merge(Conversation.assigned)
  end
end
