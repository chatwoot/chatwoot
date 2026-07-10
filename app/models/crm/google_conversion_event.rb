# == Schema Information
#
# Table name: crm_google_conversion_events
#
#  id              :bigint           not null, primary key
#  conversion_name :string           not null
#  conversion_time :datetime         not null
#  currency        :string(3)
#  gclid           :string
#  skip_reason     :string
#  status          :string           default("ready"), not null
#  value_cents     :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  activity_id     :bigint           not null
#  card_id         :bigint           not null
#  conversation_id :bigint
#  event_id        :string           not null
#
# Indexes
#
#  idx_crm_google_conv_account_status                (account_id,status)
#  idx_crm_google_conv_account_time                  (account_id,conversion_time)
#  idx_crm_google_conv_event_id                      (event_id) UNIQUE
#  index_crm_google_conversion_events_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class Crm::GoogleConversionEvent < ApplicationRecord
  self.table_name = 'crm_google_conversion_events'

  STATUSES = %w[ready skipped].freeze

  belongs_to :account
  belongs_to :card, class_name: 'Crm::Card', optional: true
  belongs_to :conversation, optional: true
  belongs_to :activity, class_name: 'Crm::Activity', optional: true

  validates :card_id, :activity_id, :event_id, :conversion_name, :conversion_time, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :currency, length: { is: 3 }, allow_nil: true
  validates :gclid, presence: true, if: -> { status == 'ready' }
  validates :skip_reason, presence: true, if: -> { status == 'skipped' }

  scope :ready, -> { where(status: 'ready') }
end
