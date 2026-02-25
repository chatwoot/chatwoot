# == Schema Information
#
# Table name: agent_bot_inboxes
#
#  id           :bigint           not null, primary key
#  status       :integer          default("active")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#  agent_bot_id :integer
#  inbox_id     :integer
#

class AgentBotInbox < ApplicationRecord
  validates :inbox_id, presence: true
  validates :agent_bot_id, presence: true
  before_validation :ensure_account_id

  belongs_to :inbox
  belongs_to :agent_bot
  belongs_to :account
  enum status: { active: 0, inactive: 1 }

  private

  def ensure_account_id
    self.account_id = inbox&.account_id
  end
end
