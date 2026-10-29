module Enterprise::Concerns::Contact
  extend ActiveSupport::Concern
  included do
    has_many :campaign_recipients, dependent: :destroy_async

    # The contacts of the given conversations, such as the records in a Copilot saved set.
    scope :of_conversations, ->(conversation_ids) { where(id: Conversation.where(id: conversation_ids).select(:contact_id)) }
  end
end
