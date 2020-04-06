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
#

class AgentBot < ApplicationRecord
  include AccessTokenable
  include Avatarable

  has_many :agent_bot_inboxes, dependent: :destroy
  has_many :inboxes, through: :agent_bot_inboxes
end
