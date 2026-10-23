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
#  ring_state           :jsonb            not null
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
#  index_calls_on_account_id_and_contact_id        (account_id,contact_id)
#  index_calls_on_account_id_and_conversation_id   (account_id,conversation_id)
#  index_calls_on_account_id_and_created_at        (account_id,created_at)
#  index_calls_on_message_id                       (message_id)
#  index_calls_on_provider_and_provider_call_id    (provider,provider_call_id) UNIQUE
#  index_calls_ringing_on_provider_and_created_at  (provider,created_at) WHERE ((status)::text = 'ringing'::text)
#
class Call < ApplicationRecord
  STATUSES = %w[ringing in_progress completed no_answer failed rejected].freeze
  TERMINAL_STATUSES = %w[completed no_answer failed rejected].freeze
  OUTSIDE_WORKING_HOURS = 'outside_working_hours'.freeze

  store_accessor :meta, :conference_sid, :twilio_conference_sid, :recording_sid, :parent_call_sid, :initiated_at, :ended_at,
                 :accepted_broadcast_at, :recording_enabled, :provider_status

  # Frontend voice bubbles/stores expect inbound/outbound string values
  DISPLAY_DIRECTION = { 'incoming' => 'inbound', 'outgoing' => 'outbound' }.freeze

  DEFAULT_STUN_URL = 'stun:stun.l.google.com:19302'.freeze

  enum :provider, { twilio: 0, whatsapp: 1 }
  enum :direction, { incoming: 0, outgoing: 1 }

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :contact, optional: true
  belongs_to :message, optional: true, inverse_of: :call
  belongs_to :accepted_by_agent, class_name: 'User', optional: true

  has_one_attached :recording

  # Snapshot the inbox's "Record calls" setting so every leg of a call agrees and a mid-call toggle can't change it.
  before_create { self.recording_enabled = inbox.channel.try(:recording_enabled?) }

  validates :provider_call_id, presence: true
  validates :provider, presence: true
  validates :direction, presence: true

  # Phones that were rung learn the ring is over; see Voice::VoipPushService
  after_update_commit :cancel_phone_ring, if: :ring_just_ended?
  # On create too: a call whose end arrived before its start is created and ended in one transaction
  after_commit :notify_missed_call, on: %i[create update], if: :missed_just_now?
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where.not(status: TERMINAL_STATUSES) }
  scope :by_conference_sid, ->(sid) { where("meta->>'conference_sid' = ?", sid) }
  scope :by_twilio_conference_sid, ->(sid) { where("meta->>'twilio_conference_sid' = ?", sid) }

  def self.find_by_provider_call_id(provider, sid)
    find_by(provider: provider, provider_call_id: sid)
  end

  def outside_working_hours?
    end_reason == OUTSIDE_WORKING_HOURS
  end

  # An inbound call nobody answered, however it ended: unanswered, or completed or failed
  # with no agent on it, as when the caller hangs up during the ring and the provider
  # reports that leg completed
  def missed?
    return false unless incoming?

    status == 'no_answer' || (%w[completed failed].include?(status) && !answered_by_agent?)
  end

  # A Twilio claim counts once the agent's leg joined the conference: the join moves an
  # inbound call to in progress and stamps started_at in the same update, before its
  # broadcast is marked. A claim whose leg never joined leaves the caller unanswered.
  def answered_by_agent?
    return false if accepted_by_agent_id.nil?

    !twilio? || started_at.present? || accepted_broadcast_at.present?
  end

  # nil = a channel with no call settings, or a call that predates them: record.
  def recording_enabled?
    recording_enabled != false
  end

  def default_conference_sid
    "conf_account_#{account_id}_call_#{id}"
  end

  # Browser ↔ Meta WebRTC needs at least one STUN server to discover its public srflx candidate.
  def self.default_ice_servers
    urls = ENV.fetch('VOICE_CALL_STUN_URLS', DEFAULT_STUN_URL).split(',').filter_map { |u| u.strip.presence }
    [{ urls: urls }]
  end

  def direction_label
    DISPLAY_DIRECTION[direction]
  end

  # Normalize filter values back to stored forms so API/dashboard clients can
  # query using either the display value (inbound/outbound, in-progress) or the
  # stored value (incoming/outgoing, in_progress).
  def self.direction_from_label(value)
    DISPLAY_DIRECTION.key(value) || value
  end

  def self.status_from_display(value)
    value.to_s.tr('-', '_')
  end

  def ringing?
    status == 'ringing'
  end

  def in_progress?
    status == 'in_progress'
  end

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  # Merges keys into `meta` in the database, leaving the other keys as they are there. A
  # save of `meta` from a copy loaded earlier would otherwise drop keys written since.
  # The agents' connections to the Twilio conference, keyed by call SID: joining from when
  # Twilio asks for the leg's instructions, then joined, or gone once it leaves or could
  # not be added. Each carries the time it last changed.
  def agent_legs
    meta&.fetch('agent_legs', nil) || {}
  end

  # How long an agent's connection counts as on its way into the conference; one not in by
  # then is taken to have failed
  AGENT_LEG_JOIN_GRACE_SECONDS = 30

  # Seconds until the last of the connections still on its way in, other than the one
  # given, runs out of time to join; nil when there is none
  def agent_leg_join_wait(except: nil)
    now = Time.zone.now.to_i
    joining = agent_legs.except(except.to_s).values.select { |leg| leg['state'] == 'joining' && leg['at'].to_i > now - AGENT_LEG_JOIN_GRACE_SECONDS }
    joining.map { |leg| leg['at'].to_i + AGENT_LEG_JOIN_GRACE_SECONDS - now }.max&.clamp(1..)
  end

  # Whether another connection is in the conference, or joined it at or after the time given
  def agent_leg_joined?(except: nil, since: nil)
    agent_legs.except(except.to_s).values.any? { |leg| leg['state'] == 'joined' && (since.nil? || leg['at'].to_i >= since) }
  end

  # A join accepted with an attempt id holds a place for its connection, until Twilio asks
  # for that connection's instructions with the same id or its time to join runs out
  def self.pending_agent_leg(attempt) = "pending:#{attempt}"

  # Records an agent's connection as joining unless the call has ended, under the row lock,
  # so a decision that ends the call either sees the connection or is seen by it. The place
  # its own attempt held is given up to it. A repeated request for a connection keeps the
  # state its callbacks already reached: one that joined stays joined, one that left is refused.
  def open_agent_leg!(sid, attempt: nil)
    with_lock do
      leg_state = agent_legs.dig(sid.to_s, 'state')
      next false if terminal? || leg_state == 'gone'

      if attempt.present?
        self.class.where(id: id).update_all(['meta = meta #- ARRAY[?, ?]', 'agent_legs', self.class.pending_agent_leg(attempt)]) # rubocop:disable Rails/SkipsModelValidations
      end
      record_agent_leg!(sid, 'joining') unless leg_state == 'joined'
      true
    end
  end

  # Called under the row lock. A leg that has gone stays gone, since Twilio's callbacks for
  # one leg can arrive out of order. Merged in place, so other webhooks' meta keys stay.
  def record_agent_leg!(sid, state)
    return if sid.blank? || agent_legs.dig(sid, 'state') == 'gone'

    leg = { sid => { 'state' => state, 'at' => Time.zone.now.to_i } }
    self.class.where(id: id).update_all( # rubocop:disable Rails/SkipsModelValidations
      ["meta = jsonb_set(COALESCE(meta, '{}'::jsonb), '{agent_legs}', COALESCE(meta->'agent_legs', '{}'::jsonb) || ?::jsonb)", leg.to_json]
    )
    reload
  end

  # Ended unanswered because the agent's leg could not be added; the contact's answer may
  # still be reported after it
  def unanswered_by_failed_join? = status == 'no_answer' && meta&.dig('unanswered_by_failed_join').present?

  # Called under the row lock
  def retire_pending_agent_legs!
    legs = agent_legs.reject { |sid, _| sid.start_with?('pending:') }
    self.class.where(id: id).update_all(["meta = jsonb_set(COALESCE(meta, '{}'::jsonb), '{agent_legs}', ?::jsonb)", legs.to_json]) # rubocop:disable Rails/SkipsModelValidations
    reload
  end

  def merge_meta!(values)
    self.class.where(id: id).update_all(["meta = COALESCE(meta, '{}'::jsonb) || ?::jsonb", values.to_json]) # rubocop:disable Rails/SkipsModelValidations
    reload
  end

  # The ring timeout is hanging the caller up. A mark left by an attempt that died long ago
  # no longer counts, so a later sweep can finish the job.
  def ring_timeout_in_progress?
    started_at = ring_state['timing_out_at']
    started_at.present? && started_at > Voice::RingingTimeoutService::ATTEMPT_TTL_SECONDS.seconds.ago.to_i
  end

  def display_status
    status.to_s.tr('_', '-')
  end

  # Payload shape matches Whatsapp::CallService#broadcast so the frontend's
  # onVoiceCallAccepted/onVoiceCallEnded handlers can treat both providers uniformly.
  def broadcast_voice_call_event(event, **extra)
    payload = {
      event: "voice_call.#{event}",
      data: { id: id, call_id: provider_call_id, provider: provider,
              conversation_id: conversation_id, account_id: account_id }.merge(extra)
    }
    ActionCable.server.broadcast("account_#{account_id}", payload)
  end

  def from_number
    incoming? ? contact&.phone_number : inbox.channel&.phone_number
  end

  def to_number
    incoming? ? inbox.channel&.phone_number : contact&.phone_number
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
      provider_status: provider_status,
      duration_seconds: duration_seconds,
      end_reason: end_reason,
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

  # The devices are read from the row, since the ring may have recorded them after this
  # instance was loaded
  def ring_just_ended?
    return false unless saved_change_to_status? && status_before_last_save == 'ringing'

    self.class.uncached { self.class.where(id: id).pick(:ring_state) }&.dig('rung_devices').present?
  end

  def cancel_phone_ring
    Voice::VoipPushJob.perform_later(id, 'cancel')
  end

  # Only a call that rang phones has a missed-call notice: the agents rung were recorded
  # as its ring started
  def missed_just_now?
    saved_change_to_status? && ring_state.key?('ring_recipient_ids') && missed?
  end

  def notify_missed_call
    Voice::MissedCallNotificationJob.perform_later(id)
  end
end
