# The conversation as it was when an automation rule started running, so the text of an action can
# name what the run itself is about to destroy ("was with John, tagged Em negociação") after the
# actions that erase it already ran. It answers the same messages ConversationDrop reads, so the
# same drop serves both the live conversation and the snapshot.
#
# Columns are copied on capture; associations are resolved lazily from the ids that were captured,
# which keeps an unused snapshot free of queries and still points at the assignee of that moment.
class ConversationSnapshot
  attr_reader :id, :display_id, :status, :priority, :custom_attributes, :additional_attributes,
              :first_reply_created_at, :last_activity_at, :created_at, :captured_at

  def initialize(conversation)
    @id = conversation.id
    @display_id = conversation.display_id
    @status = conversation.status
    @priority = conversation.priority
    @custom_attributes = (conversation.custom_attributes || {}).deep_dup.freeze
    @additional_attributes = (conversation.additional_attributes || {}).deep_dup.freeze
    @first_reply_created_at = conversation.first_reply_created_at
    @last_activity_at = conversation.last_activity_at
    @created_at = conversation.created_at
    @assignee_id = conversation.assignee_id
    @contact_id = conversation.contact_id
    @account_id = conversation.account_id
    @inbox_id = conversation.inbox_id
    @team_id = conversation.team_id
    @captured_at = Time.current
  end

  def assignee
    @assignee = User.find_by(id: @assignee_id) unless defined?(@assignee)
    @assignee
  end

  def contact
    @contact = Contact.find_by(id: @contact_id) unless defined?(@contact)
    @contact
  end

  def account
    @account = Account.find_by(id: @account_id) unless defined?(@account)
    @account
  end

  def inbox
    @inbox = Inbox.find_by(id: @inbox_id) unless defined?(@inbox)
    @inbox
  end

  def team
    @team = Team.find_by(id: @team_id) unless defined?(@team)
    @team
  end

  # Messages the run itself wrote are not part of the state it found.
  def recent_messages
    @recent_messages ||= Message.where(conversation_id: @id).chat.where(created_at: ..@captured_at).last(5)
  end

  # False for another conversation and for a snapshot, so a snapshot never stands in for a
  # conversation it was not taken from, and never carries a snapshot of its own.
  def snapshot_of?(conversation)
    conversation.is_a?(Conversation) && conversation.id.present? && conversation.id == id
  end
end
