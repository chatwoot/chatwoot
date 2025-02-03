# == Schema Information
#
# Table name: campaigns_contacts
#
#  id            :bigint           not null, primary key
#  error_message :text
#  processed_at  :datetime
#  status        :string           default("pending")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  campaign_id   :bigint           not null
#  contact_id    :bigint           not null
#  message_id    :string
#
# Indexes
#
#  index_campaigns_contacts_on_campaign_id_and_contact_id  (campaign_id,contact_id) UNIQUE
#  index_campaigns_contacts_on_message_id                  (message_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id) ON DELETE => cascade
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => cascade
#
class CampaignContact < ApplicationRecord
  self.table_name = 'campaigns_contacts'

  belongs_to :campaign
  belongs_to :contact

  validates :campaign_id, presence: true
  validates :contact_id, presence: true
  validates :status, presence: true
  validates :contact_id, uniqueness: { scope: :campaign_id }

  enum status: {
    pending: 'pending',
    processed: 'processed',
    failed: 'failed',
    delivered: 'delivered',
    read: 'read',
    replied: 'replied'
  }

  def self.find_campaign_by_message_id(message_id)
    # Find the first campaign contact with the given message ID
    campaign_contact = find_by(message_id: message_id)

    # Return the associated campaign, or nil if no matching contact found
    campaign_contact&.campaign
  end
end
