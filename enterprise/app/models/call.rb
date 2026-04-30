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

  store_accessor :meta, :conference_sid, :recording_sid, :parent_call_sid, :initiated_at, :ended_at

  enum :provider, { twilio: 0, whatsapp: 1 }
  enum :direction, { incoming: 0, outgoing: 1 }

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :contact
  belongs_to :message, optional: true, inverse_of: :call
  belongs_to :accepted_by_agent, class_name: 'User', optional: true

  has_one_attached :recording

  validates :provider_call_id, presence: true
  validates :provider, presence: true
  validates :direction, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where.not(status: TERMINAL_STATUSES) }
  scope :by_conference_sid, ->(sid) { where("meta->>'conference_sid' = ?", sid) }

  def self.find_by_provider_call_id(provider, sid)
    find_by(provider: provider, provider_call_id: sid)
  end

  def default_conference_sid
    "conf_account_#{account_id}_call_#{id}"
  end

  def display_status
    status.to_s.tr('_', '-')
  end

  def from_number
    incoming? ? contact.phone_number : inbox.channel&.phone_number
  end

  def to_number
    incoming? ? inbox.channel&.phone_number : contact.phone_number
  end

  def recording_url
    return nil unless recording.attached?

    Rails.application.routes.url_helpers.rails_blob_url(recording)
  end

  def push_event_data
    {
      id: id,
      provider_call_id: provider_call_id,
      provider: provider,
      direction: direction,
      status: display_status,
      duration_seconds: duration_seconds,
      conference_sid: conference_sid,
      accepted_by_agent_id: accepted_by_agent_id,
      accepted_by_agent_name: accepted_by_agent&.available_name,
      started_at: started_at&.to_i,
      ended_at: ended_at,
      from_number: from_number,
      to_number: to_number,
      recording_url: recording_url,
      transcript: transcript
    }
  end
end
