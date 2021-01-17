# == Schema Information
#
# Table name: contact_inboxes
#
#  id            :bigint           not null, primary key
#  hmac_verified :boolean          default(FALSE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  contact_id    :bigint
#  inbox_id      :bigint
#  source_id     :string           not null
#
# Indexes
#
#  index_contact_inboxes_on_contact_id              (contact_id)
#  index_contact_inboxes_on_inbox_id                (inbox_id)
#  index_contact_inboxes_on_inbox_id_and_source_id  (inbox_id,source_id) UNIQUE
#  index_contact_inboxes_on_source_id               (source_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#

class ContactInbox < ApplicationRecord
  validates :inbox_id, presence: true
  validates :contact_id, presence: true
  validates :source_id, presence: true

  belongs_to :contact
  belongs_to :inbox

  has_many :conversations, dependent: :destroy

  def webhook_data
    {
      id: id,
      contact: contact.try(:webhook_data),
      inbox: inbox.webhook_data,
      account: inbox.account.webhook_data,
      current_conversation: current_conversation.try(:webhook_data),
      source_id: source_id
    }
  end

  def current_conversation
    conversations.last
  end
end
