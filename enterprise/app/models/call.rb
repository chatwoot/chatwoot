# == Schema Information
#
# Table name: calls
#
#  id                   :bigint           not null, primary key
#  direction            :integer          not null
#  duration_seconds     :integer
#  end_reason           :string
#  meta                 :jsonb
#  provider             :integer          default("twilio"), not null
#  started_at           :datetime
#  status               :string           default("ringing"), not null
#  transcript           :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  accepted_by_agent_id :bigint
#  account_id           :bigint           not null
#  contact_id           :bigint           not null
#  conversation_id      :bigint           not null
#  inbox_id             :bigint           not null
#  message_id           :bigint
#  provider_call_id     :string           not null
#
# Indexes
#
#  index_calls_on_account_id_and_contact_id       (account_id,contact_id)
#  index_calls_on_account_id_and_conversation_id  (account_id,conversation_id)
#  index_calls_on_message_id                      (message_id)
#  index_calls_on_provider_and_provider_call_id   (provider,provider_call_id) UNIQUE
#
class Call < ApplicationRecord
  # All valid call statuses
  STATUSES = %w[ringing in_progress completed no_answer failed].freeze
  # Statuses where the call is finished and won't change again
  TERMINAL_STATUSES = %w[completed no_answer failed].freeze

  enum :provider, { twilio: 0, whatsapp: 1 }
  enum :direction, { incoming: 0, outgoing: 1 }

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :contact
  belongs_to :message, optional: true
  belongs_to :accepted_by_agent, class_name: 'User', optional: true

  has_one_attached :recording

  validates :provider_call_id, presence: true
  validates :provider, presence: true
  validates :direction, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where.not(status: TERMINAL_STATUSES) }
end
