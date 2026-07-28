# == Schema Information
#
# Table name: captain_conversation_outcomes
#
#  id                      :bigint           not null, primary key
#  captain_involved_at     :datetime
#  captain_reply_count     :integer          default(0), not null
#  csat_rating             :integer
#  csat_received_at        :datetime
#  durable_resolved_at     :datetime
#  eligible_at             :datetime         not null
#  first_captain_reply_at  :datetime
#  first_human_reply_at    :datetime
#  first_reopened_at       :datetime
#  first_response_seconds  :integer
#  handoff_at              :datetime
#  handoff_reason          :text
#  handoff_reason_category :string
#  last_captain_reply_at   :datetime
#  last_reopened_at        :datetime
#  reopen_count            :integer          default(0), not null
#  resolution_seconds      :integer
#  resolution_type         :integer
#  resolved_at             :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  account_id              :bigint           not null
#  assistant_id            :bigint           not null
#  conversation_id         :bigint           not null
#  inbox_id                :bigint           not null
#
class Captain::ConversationOutcome < ApplicationRecord
  self.table_name = 'captain_conversation_outcomes'

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :conversation, class_name: '::Conversation'
  belongs_to :inbox

  enum :resolution_type, { autonomous: 0, assisted: 1 }, prefix: :resolution

  validates :eligible_at, presence: true
  validates :conversation_id, uniqueness: { scope: [:account_id, :assistant_id] }
  validates :captain_reply_count, :reopen_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :csat_rating, inclusion: { in: 1..5 }, allow_nil: true

  validate :dimensions_belong_to_account
  validate :inbox_matches_conversation

  private

  def dimensions_belong_to_account
    return if account.blank?

    { assistant: assistant, conversation: conversation, inbox: inbox }.each do |dimension, record|
      errors.add(dimension, 'must belong to the outcome account') if record.present? && record.account_id != account_id
    end
  end

  def inbox_matches_conversation
    return if conversation.blank? || inbox.blank? || conversation.inbox_id == inbox_id

    errors.add(:inbox, 'must match the conversation inbox')
  end
end
