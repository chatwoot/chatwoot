# == Schema Information
#
# Table name: conversation_participants
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_conversation_participants_on_account_id       (account_id)
#  index_conversation_participants_on_conversation_id  (conversation_id)
#  index_conversation_participants_on_user_id          (user_id)
#
class ConversationParticipant < ApplicationRecord
  validates :account_id, presence: true
  validates :conversation_id, presence: true
  validates :user_id, presence: true

  belongs_to :account
  belongs_to :conversation
  belongs_to :user

  before_validation :ensure_account_id

  private

  def ensure_account_id
    self.account_id = conversation&.account_id
  end
end
