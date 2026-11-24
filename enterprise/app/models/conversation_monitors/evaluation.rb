# == Schema Information
#
# Table name: conversation_monitor_evaluations
#
#  id                :bigint           not null, primary key
#  error_code        :string
#  evaluated_at      :datetime
#  first_matched_at  :datetime
#  generation        :bigint           default(0), not null
#  input_revision    :bigint           default(0), not null
#  matched_at        :datetime
#  model             :string
#  requested_version :bigint
#  score             :float
#  status            :string           default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  conversation_id   :bigint           not null
#  monitor_id        :bigint           not null
#
# Indexes
#
#  index_conversation_monitor_evaluations_on_account_id       (account_id)
#  index_conversation_monitor_evaluations_on_conversation_id  (conversation_id)
#  index_conversation_monitor_evaluations_on_monitor_id       (monitor_id)
#  index_monitor_evaluations_status                           (monitor_id,status,conversation_id)
#  index_monitor_evaluations_unique                           (monitor_id,conversation_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (monitor_id => conversation_monitors.id) ON DELETE => cascade
#
class ConversationMonitors::Evaluation < ApplicationRecord
  self.table_name = 'conversation_monitor_evaluations'

  belongs_to :account
  belongs_to :monitor, class_name: 'ConversationMonitors::Monitor', inverse_of: :evaluations
  belongs_to :conversation

  validates :conversation_id, uniqueness: { scope: :monitor_id }
  validates :status, inclusion: { in: %w[pending matched unmatched error skipped] }
  validate :same_account

  private

  def same_account
    return if account_id == monitor&.account_id && account_id == conversation&.account_id

    errors.add(:account, 'must own the monitor and conversation')
  end
end
