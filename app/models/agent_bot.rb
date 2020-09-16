# == Schema Information
#
# Table name: agent_bots
#
#  id                               :bigint           not null, primary key
#  description                      :string
#  hide_input_for_bot_conversations :boolean          default(FALSE)
#  name                             :string
#  outgoing_url                     :string
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#

class AgentBot < ApplicationRecord
  include AccessTokenable
  include Avatarable

  has_many :agent_bot_inboxes, dependent: :destroy
  has_many :inboxes, through: :agent_bot_inboxes
  has_many :messages, as: :sender, dependent: :restrict_with_exception

  def available_name
    name
  end

  def push_event_data(inbox = nil)
    {
      id: id,
      name: name,
      avatar_url: avatar_url || inbox&.avatar_url,
      type: 'agent_bot'
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      type: 'agent_bot'
    }
  end
end
