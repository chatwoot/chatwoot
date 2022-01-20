# == Schema Information
#
# Table name: automation_rules
#
#  id          :bigint           not null, primary key
#  actions     :jsonb            not null
#  active      :boolean          default(TRUE), not null
#  conditions  :jsonb            not null
#  description :text
#  event_name  :string           not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_automation_rules_on_account_id  (account_id)
#
class AutomationRule < ApplicationRecord
  belongs_to :account

  validates :account, presence: true
  validate :json_conditions_format
  validate :json_actions_format

  scope :active, -> { where(active: true) }

  CONDITIONS_ATTRS = %w[country_code status browser_language assignee_id team_id referer].freeze
  ACTIONS_ATTRS = %w[send_message add_label send_email_to_team assign_team assign_best_agents].freeze

  private

  def json_conditions_format
    return if conditions.nil?

    attributes = conditions.map { |obj, _| obj['attribute_key'] }
    (attributes - CONDITIONS_ATTRS).blank?
  end

  def json_actions_format
    return if actions.nil?

    attributes = actions.map { |obj, _| obj['attribute_key'] }
    (attributes - ACTIONS_ATTRS).blank?
  end
end
