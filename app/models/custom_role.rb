# == Schema Information
#
# Table name: custom_roles
#
#  id          :bigint           not null, primary key
#  description :string
#  name        :string
#  permissions :text             default([]), is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_custom_roles_on_account_id  (account_id)
#

class CustomRole < ApplicationRecord
  PERMISSIONS = %w[
    conversation_manage
    conversation_unassigned_manage
    conversation_participating_manage
    contact_manage
    report_manage
    knowledge_base_manage
  ].freeze

  belongs_to :account
  has_many :account_users, dependent: :nullify

  validates :name, presence: true
  validate :permissions_must_be_allowed

  private

  def permissions_must_be_allowed
    invalid_permissions = Array(permissions) - PERMISSIONS
    return if invalid_permissions.blank?

    errors.add(:permissions, :inclusion)
  end
end
