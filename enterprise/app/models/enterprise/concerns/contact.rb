module Enterprise::Concerns::Contact
  extend ActiveSupport::Concern
  included do
    has_many :campaign_recipients, dependent: :destroy_async

    # The contacts of the given conversations or messages, such as the records in a Copilot saved set.
    scope :of_conversations, ->(conversation_ids) { where(id: Conversation.where(id: conversation_ids).select(:contact_id)) }
    scope :of_messages, ->(message_ids) { of_conversations(Message.where(id: message_ids).select(:conversation_id)) }
  end
end
