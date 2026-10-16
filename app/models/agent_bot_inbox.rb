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
  validate :ensure_exclusive_bot_provider,
           if: -> { active? && (new_record? || will_save_change_to_status? || will_save_change_to_inbox_id? || will_save_change_to_agent_bot_id?) }
  before_validation :ensure_account_id

  belongs_to :inbox
  belongs_to :agent_bot
  belongs_to :account
  enum status: { active: 0, inactive: 1 }

  private

  def ensure_exclusive_bot_provider
    provider = inbox&.conflicting_bot_provider(:agent_bot)
    errors.add(:base, I18n.t('errors.inboxes.bot_provider_conflict', current_provider: provider, requested_provider: 'Agent Bot')) if provider
  end

  def ensure_account_id
    self.account_id = inbox&.account_id
  end
end
