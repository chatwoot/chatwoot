# == Schema Information
#
# Table name: channel_shopees
#
#  id            :bigint           not null, primary key
#  access_token  :string           not null
#  expires_at    :datetime         not null
#  refresh_token :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#  partner_id    :integer          not null
#  shop_id       :integer          not null
#
# Indexes
#
#  index_channel_shopees_on_account_id_and_shop_id  (account_id,shop_id) UNIQUE
#
class Channel::Shopee < ApplicationRecord
  include Channelable
  include Reauthorizable

  validates :partner_id, presence: true
  validates :shop_id, presence: true, uniqueness: { scope: :account_id }

  def name
    'Shopee'
  end

  def refresh_access_token!
    response = Integrations::Shopee::Auth.new(shop_id: shop_id).refresh_access_token(refresh_token)
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
