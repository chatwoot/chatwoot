# == Schema Information
#
# Table name: agent_capacity_policies
#
#  id              :bigint           not null, primary key
#  description     :text
#  exclusion_rules :jsonb            not null
#  name            :string(255)      not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#
# Indexes
#
#  index_agent_capacity_policies_on_account_id  (account_id)
#
class AgentCapacityPolicy < ApplicationRecord
  MAX_NAME_LENGTH = 255

  belongs_to :account
  has_many :inbox_capacity_limits, dependent: :destroy
  has_many :inboxes, through: :inbox_capacity_limits
  has_many :account_users, dependent: :nullify

  validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }
  validates :account, presence: true
end
