# == Schema Information
#
# Table name: agent_bots
#
#  id           :bigint           not null, primary key
#  bot_config   :jsonb
#  bot_type     :integer          default(0)
#  description  :string
#  name         :string
#  outgoing_url :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint
#
# Indexes
#
#  index_agent_bots_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#

class AgentBot < ApplicationRecord
  include AccessTokenable
  include Avatarable

  has_many :agent_bot_inboxes, dependent: :destroy_async
  has_many :inboxes, through: :agent_bot_inboxes
  has_many :messages, as: :sender, dependent: :restrict_with_exception
  belongs_to :account, optional: true
  enum bot_type: { webhook: 0, csml: 1 }

  validate :validate_agent_bot_config

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

  private

  def validate_agent_bot_config
    errors.add(:bot_config, 'Invalid Bot Configuration') unless AgentBots::ValidateBotService.new(agent_bot: self).perform
  end
end
