# == Schema Information
#
# Table name: platform_app_permissibles
#
#  id               :bigint           not null, primary key
#  permissible_type :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  permissible_id   :bigint           not null
#  platform_app_id  :bigint           not null
#
# Indexes
#
#  index_platform_app_permissibles_on_permissibles     (permissible_type,permissible_id)
#  index_platform_app_permissibles_on_platform_app_id  (platform_app_id)
#  unique_permissibles_index                           (platform_app_id,permissible_id,permissible_type) UNIQUE
#
class PlatformAppPermissible < ApplicationRecord
  validates :platform_app, presence: true
  validates :platform_app_id, uniqueness: { scope: [:permissible_id, :permissible_type] }

  belongs_to :platform_app
  belongs_to :permissible, polymorphic: true
end
