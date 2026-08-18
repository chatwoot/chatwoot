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
#  index_calls_on_account_id_and_created_at       (account_id,created_at)
#  index_calls_on_message_id                      (message_id)
#  index_calls_on_provider_and_provider_call_id   (provider,provider_call_id) UNIQUE
#

class Call < ApplicationRecord
  # Persisted (snake_case) statuses. The dashboard bubble expects the dashed
  # display form, so `push_event_data` maps them through DISPLAY_STATUSES.
  STATUSES = %w[ringing in_progress completed no_answer failed rejected].freeze
  # Once a call reaches one of these it can never go back to a live state.
  TERMINAL_STATUSES = %w[completed no_answer failed rejected].freeze
  DISPLAY_STATUSES = { 'in_progress' => 'in-progress', 'no_answer' => 'no-answer' }.freeze
  # Calls handled end-to-end by the Pathors voice agent have no human answerer,
  # so the bubble gets a synthetic handler name instead of a blank subtext.
  PATHORS_AGENT_NAME = 'Pathors AI'.freeze

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :contact
  belongs_to :message, optional: true
  belongs_to :accepted_by_agent, class_name: 'User', optional: true

  # 0/1 are pinned by existing rows; only new values may be appended.
  enum provider: { twilio: 0, whatsapp: 1, pathors: 2 }
  enum direction: { incoming: 0, outgoing: 1 }

  # `calls` has no columns for these, so they live in the jsonb meta blob.
  # `room_name` is unused in P1 and reserved for the P2 live-audio bridge.
  store_accessor :meta, :room_name, :ended_at, :from_number, :to_number, :recording_url

  validates :provider_call_id, presence: true, uniqueness: { scope: :provider }
  validates :status, inclusion: { in: STATUSES }

  def self.normalize_timestamp(value)
    return nil if value.blank?
    return value.iso8601 if value.respond_to?(:iso8601)

    Time.zone.parse(value.to_s)&.iso8601
  rescue ArgumentError
    nil
  end

  # Keep the meta-backed timestamp in a single, comparable representation.
  def ended_at=(value)
    super(self.class.normalize_timestamp(value))
  end

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  def display_status
    DISPLAY_STATUSES.fetch(status, status)
  end

  def accepted_by_agent_name
    return accepted_by_agent.available_name if accepted_by_agent.present?

    pathors? ? PATHORS_AGENT_NAME : nil
  end

  # Consumed by app/views/api/v1/models/_message.json.jbuilder and by
  # Message#push_event_data (websocket). Keys are snake_case; the dashboard
  # camelizes them before the VoiceCall bubble reads them.
  def push_event_data
    {
      id: id,
      provider_call_id: provider_call_id,
      provider: provider,
      direction: direction,
      status: display_status,
      duration_seconds: duration_seconds,
      end_reason: end_reason,
      # Twilio-only in the upstream shape; emitted as nil for shape-compat.
      conference_sid: nil,
      accepted_by_agent_id: accepted_by_agent_id,
      accepted_by_agent_name: accepted_by_agent_name,
      started_at: started_at&.iso8601,
      ended_at: ended_at,
      from_number: from_number,
      to_number: to_number,
      # Written back by the Pathors backend once the recording is finalized, so it
      # stays nil for the whole live phase of the call.
      recording_url: recording_url,
      transcript: transcript
    }
  end
end
