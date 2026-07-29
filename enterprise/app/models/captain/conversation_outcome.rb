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
