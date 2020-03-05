# == Schema Information
#
# Table name: agent_bot_inboxes
#
#  id           :bigint           not null, primary key
#  status       :integer          default("active")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  agent_bot_id :integer
#  inbox_id     :integer
#

class AgentBotInbox < ApplicationRecord
  validates :inbox_id, presence: true
  validates :agent_bot_id, presence: true

  belongs_to :inbox
  belongs_to :agent_bot
  enum status: { active: 0, inactive: 1 }
end
