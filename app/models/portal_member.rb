# == Schema Information
#
# Table name: portal_members
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  portal_id  :bigint
#  user_id    :bigint
#
# Indexes
#
#  index_portal_members_on_portal_id_and_user_id  (portal_id,user_id) UNIQUE
#  index_portal_members_on_user_id_and_portal_id  (user_id,portal_id) UNIQUE
#
class PortalMember < ApplicationRecord
  belongs_to :portal, class_name: 'Portal'
  belongs_to :user, class_name: 'User'
  validates :user_id, uniqueness: { scope: :portal_id }
end
