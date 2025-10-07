# == Schema Information
#
# Table name: campaign_contacts
#
#  id            :bigint           not null, primary key
#  error_message :text
#  metadata      :jsonb
#  sent_at       :datetime
#  status        :integer          default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  campaign_id   :bigint           not null
#  contact_id    :bigint           not null
#
# Indexes
#
#  index_campaign_contacts_on_campaign_id                 (campaign_id)
#  index_campaign_contacts_on_campaign_id_and_contact_id  (campaign_id,contact_id) UNIQUE
#  index_campaign_contacts_on_contact_id                  (contact_id)
#  index_campaign_contacts_on_status                      (status)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (contact_id => contacts.id)
#
class CampaignContact < ApplicationRecord
  belongs_to :campaign
  belongs_to :contact

  enum status: { pending: 0, sent: 1, failed: 2, skipped: 3 }

  validates :campaign_id, uniqueness: { scope: :contact_id }

  scope :sent_successfully, -> { where(status: :sent) }
  scope :with_errors, -> { where(status: :failed) }
  scope :not_sent, -> { where(status: [:pending, :skipped]) }

  def mark_as_sent!
    update!(status: :sent, sent_at: Time.current)
  end

  def mark_as_failed!(error)
    update!(status: :failed, error_message: error, sent_at: Time.current)
  end

  def mark_as_skipped!(reason)
    update!(status: :skipped, error_message: reason)
  end
end
