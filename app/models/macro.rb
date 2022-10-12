# == Schema Information
#
# Table name: macros
#
#  id            :bigint           not null, primary key
#  actions       :jsonb            not null
#  name          :string           not null
#  visibility    :integer          default("personal")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  created_by_id :bigint           not null
#  updated_by_id :bigint           not null
#
# Indexes
#
#  index_macros_on_account_id     (account_id)
#  index_macros_on_created_by_id  (created_by_id)
#  index_macros_on_updated_by_id  (updated_by_id)
#
class Macro < ApplicationRecord
  belongs_to :account
  belongs_to :created_by,
             class_name: :User
  belongs_to :updated_by,
             class_name: :User
  enum visibility: { personal: 0, global: 1 }

  validate :json_actions_format

  ACTIONS_ATTRS = %w[send_message add_label send_email_to_team assign_team assign_best_agent send_webhook_event mute_conversation change_status
                     resolve_conversation snooze_conversation].freeze

  def set_visibility(user, params)
    self.visibility = params[:visibility]
    self.visibility = :personal if user.agent?
  end

  def self.with_visibility(user, params)
    records = user.administrator? ? Current.account.macros : Current.account.macros.global
    records = records.or(personal.where(created_by_id: user.id)) if user.agent?
    records.page(current_page(params))
    records
  end

  def self.current_page(params)
    params[:page] || 1
  end

  private

  def json_actions_format
    return if actions.blank?

    attributes = actions.map { |obj, _| obj['action_name'] }
    actions = attributes - ACTIONS_ATTRS

    errors.add(:actions, "Macro execution actions #{actions.join(',')} not supported.") if actions.any?
  end
end
