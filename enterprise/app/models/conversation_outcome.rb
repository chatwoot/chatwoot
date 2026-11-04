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
class ConversationOutcome < ApplicationRecord
  HANDOFF_REASON_CATEGORIES = %w[
    customer_request
    missing_knowledge
    unsupported_request
    policy_restriction
    tool_failure
    pending_clarification
    usage_limit
  ].freeze

  EPISODE_TRIGGERS = %w[
    initial
    reopen
    assignment
  ].freeze

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :conversation, class_name: '::Conversation'
  belongs_to :inbox

  enum :handoff_reason_category,
       HANDOFF_REASON_CATEGORIES.index_by(&:itself),
       prefix: :handoff_reason,
       validate: { allow_nil: true }

  enum :episode_trigger,
       EPISODE_TRIGGERS.index_by(&:itself),
       prefix: :trigger,
       validate: true

  validates :started_at, presence: true, uniqueness: { scope: [:account_id, :conversation_id] }
  validate :associations_must_belong_to_account

  scope :chronological, -> { order(:started_at) }

  # The half-open episode window [started_at, ended_at); ended_at is nil for
  # the stream's latest episode.
  scope :covering, lambda { |at|
    where(started_at: ..at).where('ended_at IS NULL OR ended_at > ?', at)
  }

  private

  def associations_must_belong_to_account
    [:assistant, :conversation, :inbox].each do |association|
      record = public_send(association)
      errors.add(association, 'must belong to the same account') if record && record.account_id != account_id
    end
  end
end
