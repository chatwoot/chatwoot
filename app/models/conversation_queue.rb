# == Schema Information
#
# Table name: conversation_queues
#
#  id              :bigint           not null, primary key
#  assigned_at     :datetime
#  left_at         :datetime
#  position        :integer          not null
#  queued_at       :datetime         not null
#  status          :integer          default("waiting"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  inbox_id        :bigint
#
# Indexes
#
#  idx_on_account_id_status_position_c5e04b77ac   (account_id,status,position)
#  idx_on_account_id_status_queued_at_960ec2cf36  (account_id,status,queued_at)
#  index_conversation_queues_on_account_id        (account_id)
#  index_conversation_queues_on_conversation_id   (conversation_id) UNIQUE
#  index_conversation_queues_on_inbox_id          (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#
class ConversationQueue < ApplicationRecord
  belongs_to :conversation
  belongs_to :account

  enum status: { waiting: 0, assigned: 1, left: 2 }

  scope :waiting, -> { where(status: :waiting).order(:position, :queued_at) }
  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :for_inbox, ->(inbox_id) { where(inbox_id: inbox_id) }
  scope :for_priority_group, ->(group) {
    joins(conversation: :inbox).where(inboxes: { priority_group_id: group.id })
  }  

  validates :conversation_id, uniqueness: true
  validates :position, presence: true
  validates :inbox_id, presence: true

  before_validation :set_position, on: :create

  def wait_time_seconds
    return 0 unless assigned_at || left_at

    end_time = assigned_at || left_at
    (end_time - queued_at).to_i
  end

  private

  def set_position
    self.position = next_position
  end

  def next_position
    group = conversation.inbox.priority_group

    max_position = ConversationQueue
                   .for_account(account_id)
                   .for_priority_group(group)
                   .waiting
                   .maximum(:position) || 0
    max_position + 1
  end
end
