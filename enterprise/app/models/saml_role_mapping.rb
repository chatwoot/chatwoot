# == Schema Information
#
# Table name: saml_role_mappings
#
#  id                       :bigint           not null, primary key
#  role                     :integer          default("agent"), not null
#  saml_group_name          :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_saml_settings_id :bigint           not null
#  custom_role_id           :bigint
#
# Indexes
#
#  index_saml_role_mappings_on_account_saml_settings_id  (account_saml_settings_id)
#  index_saml_role_mappings_on_custom_role_id            (custom_role_id)
#
class SamlRoleMapping < ApplicationRecord
  belongs_to :account_saml_settings
  belongs_to :custom_role, optional: true

  validates :saml_group_name, presence: true
  validates :role, inclusion: { in: [0, 1] }, allow_nil: true
  validate :role_or_custom_role_present
  validate :not_both_role_and_custom_role

  enum role: { agent: 0, administrator: 1 }

  scope :for_group, ->(group_name) { where(saml_group_name: group_name) }

  def target_role
    custom_role_id? ? :custom : role
  end

  private

  def role_or_custom_role_present
    return if role.present? || custom_role_id.present?

    errors.add(:base, 'Either role or custom_role must be present')
  end

  def not_both_role_and_custom_role
    return unless role.present? && custom_role_id.present?

    errors.add(:base, 'Cannot have both role and custom_role set')
  end
end
