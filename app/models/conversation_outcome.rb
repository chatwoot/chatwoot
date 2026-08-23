# == Schema Information
#
# Table name: conversation_outcomes
#
#  id                      :bigint           not null, primary key
#  captain_reply_count     :integer          default(0), not null
#  csat_rating             :integer
#  csat_received_at        :datetime
#  ended_at                :datetime
#  episode_trigger         :string           default("initial"), not null
#  first_captain_reply_at  :datetime
#  first_human_reply_at    :datetime
#  handoff_at              :datetime
#  handoff_reason_category :string
#  last_captain_reply_at   :datetime
#  resolved_at             :datetime
#  started_at              :datetime         not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint           not null
#  assistant_id            :bigint           not null
#  conversation_id         :bigint           not null
#  inbox_id                :bigint           not null
#
# Indexes
#
#  idx_conversation_outcomes_initial_episode           (account_id,conversation_id) UNIQUE WHERE ((episode_trigger)::text = 'initial'::text)
#  idx_conversation_outcomes_on_assistant_handoff_at   (account_id,assistant_id,handoff_at)
#  idx_conversation_outcomes_on_assistant_resolved_at  (account_id,assistant_id,resolved_at)
#  idx_conversation_outcomes_on_assistant_started_at   (account_id,assistant_id,started_at)
#  idx_conversation_outcomes_open_episode              (account_id,conversation_id) UNIQUE WHERE (ended_at IS NULL)
#  idx_conversation_outcomes_unique_boundary           (account_id,conversation_id,started_at) UNIQUE
#  index_conversation_outcomes_on_account_id           (account_id)
#  index_conversation_outcomes_on_assistant_id         (assistant_id)
#  index_conversation_outcomes_on_conversation_id      (conversation_id)
#  index_conversation_outcomes_on_inbox_id             (inbox_id)
#
# One row per assistant per conversation episode. Records whether the assistant
# participated, auto-resolved, handed off, reopened, and the CSAT received, so the
# Captain stats builders can report outcomes without re-deriving them per query.
class ConversationOutcome < ApplicationRecord
  USAGE_LIMIT_REASON = 'usage_limit'.freeze

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :conversation
  belongs_to :inbox

  # The initial episode that opens the conversation's outcome timeline.
  scope :trigger_initial, -> { where(episode_trigger: 'initial') }

  # Episodes sorted by start time, oldest first.
  scope :chronological, -> { order(started_at: :asc) }

  # Episodes that are active at the given moment: started by then and not yet
  # ended, or ended after it.
  scope :covering, lambda { |time|
    where(started_at: ..time).where('ended_at IS NULL OR ended_at >= ?', time)
  }

  # Instance-level mirrors of Captain::AssistantOutcomeClassification's Arel
  # predicates, for per-record reasoning (e.g. drilldown and intent reporting)
  # where building raw SQL fragments would be impractical.

  # The assistant participated: it replied, or it handed off for a reason other
  # than a pre-participation usage limit.
  def involved?
    first_captain_reply_at.present? ||
      (handoff_at.present? && handoff_reason_category != USAGE_LIMIT_REASON)
  end

  # Closed by the assistant alone: resolved, it replied, no handoff, and any
  # human reply came only after resolution.
  def autonomous?
    return false unless resolved_at.present? && first_captain_reply_at.present? && handoff_at.nil?

    first_human_reply_at.nil? || first_human_reply_at > resolved_at
  end

  # Handed off to a human (includes usage-limit transfers that followed a reply).
  def handoff?
    involved? && handoff_at.present?
  end
end
