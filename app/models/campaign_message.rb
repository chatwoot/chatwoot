# == Schema Information
#
# Table name: campaign_messages
#
#  id                :bigint           not null, primary key
#  delivered_at      :datetime
#  error_code        :string
#  error_description :text
#  read_at           :datetime
#  sent_at           :datetime
#  status            :string           default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  campaign_id       :bigint           not null
#  contact_id        :bigint           not null
#  message_id        :string
#
# Indexes
#
#  index_campaign_messages_on_campaign_id             (campaign_id)
#  index_campaign_messages_on_campaign_id_and_status  (campaign_id,status)
#  index_campaign_messages_on_contact_id              (contact_id)
#  index_campaign_messages_on_message_id              (message_id) UNIQUE
#  index_campaign_messages_on_status                  (status)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (contact_id => contacts.id)
#
class CampaignMessage < ApplicationRecord
  belongs_to :campaign
  belongs_to :contact

  STATUS_TYPES = %w[pending sent delivered read failed].freeze

  validates :status, presence: true, inclusion: { in: STATUS_TYPES }
  validates :message_id, uniqueness: true, allow_nil: true

  scope :by_status, ->(status) { where(status: status) }
  scope :pending, -> { by_status('pending') }
  scope :sent, -> { by_status('sent') }
  scope :delivered, -> { by_status('delivered') }
  scope :read, -> { by_status('read') }
  scope :failed, -> { by_status('failed') }

  def failed?
    status == 'failed'
  end

  def delivered?
    status == 'delivered'
  end

  def read?
    status == 'read'
  end

  def sent?
    status == 'sent'
  end
end
