# == Schema Information
#
# Table name: platform_banners
#
#  id             :bigint           not null, primary key
#  active         :boolean          default(TRUE)
#  banner_message :text             not null
#  banner_type    :integer          default("info"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class PlatformBanner < ApplicationRecord
  enum :banner_type, { info: 0, warning: 1, error: 2 }

  validates :banner_message, presence: true

  scope :active, -> { where(active: true) }
end
