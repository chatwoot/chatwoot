# == Schema Information
#
# Table name: channel_zalos
#
#  id            :bigint           not null, primary key
#  access_token  :text             not null
#  expires_at    :datetime         not null
#  meta          :jsonb            not null
#  refresh_token :text             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#  oa_id         :string           not null
#
# Indexes
#
#  index_channel_zalos_on_account_id  (account_id)
#
class Channel::Zalo < ApplicationRecord
  include Channelable
  include Reauthorizable

  belongs_to :account

  validates :oa_id, presence: true
  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expires_at, presence: true
  validates :meta, presence: true
  validates :account_id, presence: true

  def name
    'Zalo OA'
  end

  def refresh_access_token!
    auth = Integrations::Zalo::Auth.new.refresh_access_token(refresh_token)
    update!({
              access_token: auth['access_token'],
              refresh_token: auth['refresh_token'],
              expires_at: auth['expires_in'].to_i.seconds.from_now,
            })
    reauthorized!
  rescue StandardError
    authorization_error!
  end

  def expire_in?(time)
    expires_at.before?(time.from_now)
  end
end
