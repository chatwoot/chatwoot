class ContactInbox < ApplicationRecord
  validates :inbox_id, presence: true
  validates :contact_id, presence: true
  validates :source_id, presence: true

  belongs_to :contact
  belongs_to :inbox
end
