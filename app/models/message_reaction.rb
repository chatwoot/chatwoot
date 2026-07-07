class MessageReaction < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :message
  belongs_to :sender, polymorphic: true, optional: true

  enum direction: { incoming: 0, outgoing: 1 }
  enum status: { active: 0, removed: 1 }

  validates :direction, :status, :external_message_id, presence: true
  validates :actor_external_id, presence: true, unless: -> { sender.present? }

  scope :active, -> { where(status: :active) }

  def push_event_data
    {
      id: id,
      message_id: message_id,
      conversation_id: conversation_id,
      emoji: emoji,
      reaction_type: reaction_type,
      direction: direction,
      status: status,
      sender: sender&.push_event_data,
      created_at: created_at.to_i,
      updated_at: updated_at.to_i
    }
  end

  def webhook_data
    {
      id: id,
      emoji: emoji,
      reaction_type: reaction_type,
      direction: direction,
      status: status,
      sender: sender.try(:webhook_data),
      message: message.webhook_data,
      conversation: conversation.webhook_data,
      account: account.webhook_data,
      inbox: inbox.webhook_data,
      created_at: created_at
    }
  end
end
