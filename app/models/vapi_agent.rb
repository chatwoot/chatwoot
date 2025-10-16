# == Schema Information
#
# Table name: vapi_agents
#
#  id            :bigint           not null, primary key
#  active        :boolean          default(TRUE)
#  name          :string           not null
#  phone_number  :string
#  settings      :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  inbox_id      :bigint           not null
#  vapi_agent_id :string           not null
#
# Indexes
#
#  index_vapi_agents_on_account_id     (account_id)
#  index_vapi_agents_on_inbox_id       (inbox_id)
#  index_vapi_agents_on_vapi_agent_id  (vapi_agent_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#

class VapiAgent < ApplicationRecord
  belongs_to :inbox
  belongs_to :account

  validates :inbox_id, presence: true
  validates :account_id, presence: true
  validates :vapi_agent_id, presence: true, uniqueness: true
  validates :name, presence: true

  # Validate that inbox belongs to account
  validate :inbox_belongs_to_account

  scope :active, -> { where(active: true) }

  private

  def inbox_belongs_to_account
    return unless inbox && account

    errors.add(:inbox, 'must belong to the account') unless inbox.account_id == account_id
  end
end

