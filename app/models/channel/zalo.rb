# == Schema Information
#
# Table name: channel_zalos
#
#  id            :bigint           not null, primary key
#  access_token  :string           not null
#  expires_at    :string           not null
#  meta          :jsonb            not null
#  refresh_token :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#  oa_id         :string           not null
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
    response = Integrations::Zalo::Auth.new(oa_id: oa_id).refresh_access_token(refresh_token)
    update!({
              access_token: response['access_token'],
              refresh_token: response['refresh_token'],
              expires_at: response['expire_in'].to_i.seconds.from_now
            })
    reauthorized!
  rescue StandardError
    authorization_error!
  end

  def expire_in?(time)
    expires_at.before?(time.from_now)
  end
end
