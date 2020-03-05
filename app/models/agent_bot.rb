# == Schema Information
#
# Table name: agent_bots
#
#  id           :bigint           not null, primary key
#  auth_token   :string
#  description  :string
#  name         :string
#  outgoing_url :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class AgentBot < ApplicationRecord
  include Avatarable
  has_many :agent_bot_inboxes, dependent: :destroy
  has_many :inboxes, through: :agent_bot_inboxes
  has_secure_token :auth_token
end
