# == Schema Information
#
# Table name: captain_conversation_outcomes
#
#  id                      :bigint           not null, primary key
#  captain_reply_count     :integer          default(0), not null
#  csat_rating             :integer
#  csat_received_at        :datetime
#  first_captain_reply_at  :datetime
#  first_human_reply_at    :datetime
#  handoff_at              :datetime
#  handoff_reason_category :string
#  last_captain_reply_at   :datetime
#  last_reopened_at        :datetime
#  reopen_count            :integer          default(0), not null
#  resolved_at             :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint           not null
#  assistant_id            :bigint           not null
#  conversation_id         :bigint           not null
#  inbox_id                :bigint           not null
#
# Indexes
#
#  idx_captain_outcomes_on_assistant_handoff_at            (account_id,assistant_id,handoff_at)
#  idx_captain_outcomes_on_assistant_resolved_at           (account_id,assistant_id,resolved_at)
#  idx_captain_outcomes_unique_conversation                (account_id,assistant_id,conversation_id) UNIQUE
#  index_captain_conversation_outcomes_on_account_id       (account_id)
#  index_captain_conversation_outcomes_on_assistant_id     (assistant_id)
#  index_captain_conversation_outcomes_on_conversation_id  (conversation_id)
#  index_captain_conversation_outcomes_on_inbox_id         (inbox_id)
#
class Captain::ConversationOutcome < ApplicationRecord
  HANDOFF_REASON_CATEGORIES = %w[
    customer_request
    missing_knowledge
    unsupported_request
    policy_restriction
    tool_failure
    pending_clarification
    usage_limit
  ].freeze

  # Query-time classification predicates: the table stores only facts, and every
  # judgment is derived from them. Shared by the stats and drilldown builders so
  # a stat card and its drilldown always count the same rows.
  #
  # Involved: Captain replied publicly, or handed off for a real reason. A
  # usage-limit handoff is blocked demand, not participation.
  INVOLVED_SQL = "(first_captain_reply_at IS NOT NULL OR (handoff_at IS NOT NULL AND handoff_reason_category != 'usage_limit'))".freeze
  # Autonomous: resolved by Captain alone, with no handoff and no public human
  # reply before the resolution that stuck.
  AUTONOMOUS_SQL = '(resolved_at IS NOT NULL AND first_captain_reply_at IS NOT NULL AND handoff_at IS NULL ' \
                   'AND (first_human_reply_at IS NULL OR first_human_reply_at > resolved_at))'.freeze
  # The tracker only records reopens that happen after the current resolution,
  # so a reopen timestamp at or before resolved_at belongs to an earlier,
  # superseded resolution.
  NOT_REOPENED_SQL = '(last_reopened_at IS NULL OR last_reopened_at <= resolved_at)'.freeze

  scope :autonomous_resolved, -> { where(AUTONOMOUS_SQL) }

  self.table_name = 'captain_conversation_outcomes'

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :conversation, class_name: '::Conversation'
  belongs_to :inbox

  enum :handoff_reason_category,
       HANDOFF_REASON_CATEGORIES.index_by(&:itself),
       prefix: :handoff_reason,
       validate: { allow_nil: true }

  validates :conversation_id, uniqueness: { scope: [:account_id, :assistant_id] }
  validates :handoff_reason_category, presence: true, if: :handoff_at?
end
