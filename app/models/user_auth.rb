# == Schema Information
#
# Table name: user_auths
#
#  id                  :bigint           not null, primary key
#  access_token        :text             not null
#  client_secret       :string           not null
#  expiration_datetime :datetime         not null
#  refresh_token       :text             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  client_id           :string           not null
#  tenant_id           :string           not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_user_auths_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserAuth < ApplicationRecord
  belongs_to :user

  scope :expiring_soon, -> { where('expiration_datetime <= ?', 2.day.from_now) }

  def self.token_by_email(email)
    user = User.from_email(email)
    return nil unless user

    find_by(user_id: user.id)&.access_token
  end

  def schedule_refresh_token
    Digitaltolk::RefreshTokenJob.perform_later(self)
  end

  def perform_refresh_token!
    result = Digitaltolk::Auth::Refresh.new(refresh_token).perform
    return if result.blank?

    Digitaltolk::Auth::UpdateUserAuth.new(user, result).perform
  end
end
