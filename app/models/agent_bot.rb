# == Schema Information
#
# Table name: agent_bots
#
#  id           :bigint           not null, primary key
#  description  :string
#  name         :string
#  outgoing_url :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#  user_id      :integer
#

class AgentBot < ApplicationRecord
  validates :account_id, presence: true
  validates :user_id, presence: true

  belongs_to :account
  belongs_to :user
  has_many :agent_bot_inboxes, dependent: :destroy
  has_many :inboxes, through: :agent_bot_inboxes
end
