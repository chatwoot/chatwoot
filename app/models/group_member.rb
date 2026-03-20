# == Schema Information
#
# Table name: group_members
#
#  id               :bigint           not null, primary key
#  is_active        :boolean          default(TRUE), not null
#  role             :integer          default("member"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  contact_id       :bigint           not null
#  group_contact_id :bigint           not null
#
# Indexes
#
#  index_group_members_on_contact_id                       (contact_id)
#  index_group_members_on_group_contact_id                 (group_contact_id)
#  index_group_members_on_group_contact_id_and_contact_id  (group_contact_id,contact_id) UNIQUE
#  index_group_members_on_group_contact_id_and_is_active   (group_contact_id,is_active)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (group_contact_id => contacts.id)
#
class GroupMember < ApplicationRecord
  belongs_to :group_contact, class_name: 'Contact'
  belongs_to :contact

  enum role: { member: 0, admin: 1 }

  validates :group_contact_id, uniqueness: { scope: :contact_id }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
end
