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
#

# Aavailable permissions for custom roles
# 'conversation_manage' - Can manage all conversations
# 'conversation_unassigned_manage' - Can manage unassigned conversations & assign to self
# 'conversation_participating_manage' - Can manage conversations they are participating in ( assigned in or is a participant )
#
class CustomRole < ApplicationRecord
  belongs_to :account
  has_many :account_users

  validates :permissions, inclusion: { in: %w[conversation_manage conversation_unassigned_manage conversation_participating_manage] }
end
