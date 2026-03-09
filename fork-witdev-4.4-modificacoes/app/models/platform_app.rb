# == Schema Information
#
# Table name: platform_apps
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class PlatformApp < ApplicationRecord
  include AccessTokenable

  validates :name, presence: true

  has_many :platform_app_permissibles, dependent: :destroy_async
end
