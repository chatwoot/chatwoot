# == Schema Information
#
# Table name: user_sessions
#
#  id               :bigint           not null, primary key
#  browser_name     :string
#  browser_version  :string
#  city             :string
#  country          :string
#  country_code     :string
#  device_name      :string
#  ip_address       :string
#  last_activity_at :datetime
#  platform_name    :string
#  platform_version :string
#  user_agent       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  client_id        :string           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_user_sessions_on_user_id                (user_id)
#  index_user_sessions_on_user_id_and_client_id  (user_id,client_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class UserSession < ApplicationRecord
  ACTIVITY_THROTTLE = 5.minutes

  belongs_to :user

  validates :client_id, presence: true, uniqueness: { scope: :user_id }

  def current?(active_client_id)
    client_id == active_client_id
  end

  def should_update_activity?
    last_activity_at.nil? || last_activity_at < ACTIVITY_THROTTLE.ago
  end
end
