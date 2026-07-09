# == Schema Information
#
# Table name: crm_meta_conversion_events
#
#  id                :bigint           not null, primary key
#  ctwa_clid         :string
#  currency          :string
#  dataset_id        :string
#  error_message     :text
#  event_id          :string           not null
#  event_type        :string           not null
#  funnel_stage_type :string
#  http_code         :integer
#  sent_at           :datetime
#  source            :string           default("live"), not null
#  status            :integer          default("pending"), not null
#  value_cents       :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  card_id           :bigint
#  pipeline_id       :bigint
#
# Indexes
#
#  idx_crm_meta_conv_account_created  (account_id,created_at)
#  idx_crm_meta_conv_card             (card_id)
#  idx_crm_meta_conv_event_id         (event_id) UNIQUE
#
class Crm::MetaConversionEvent < ApplicationRecord
  self.table_name = 'crm_meta_conversion_events'

  # Ledger append-only de eventos enviados à Meta Conversions API (CTWA revenue sync).
  # Um registro por tentativa de envio; event_id é a chave de deduplicação da Meta.
  # NUNCA guarda o token da Meta — só metadados do evento e resultado do envio.
  belongs_to :account
  belongs_to :card, class_name: 'Crm::Card', optional: true

  enum status: { pending: 0, accepted: 1, skipped: 2, error: 3 }

  validates :event_id, presence: true
  validates :event_type, presence: true
  validates :status, presence: true

  scope :recentes, -> { order(created_at: :desc) }
end
