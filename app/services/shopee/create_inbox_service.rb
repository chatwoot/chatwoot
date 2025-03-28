class Shopee::CreateInboxService
  pattr_initialize [:auth_code, :shop_id, :account_id]

  def perform
    ActiveRecord::Base.transaction do
      Inbox.create!(channel: channel, account: account, name: shop_name)
    end
  end

  private

  def authentication_data
    @authentication_data ||= Integrations::Shopee::Auth.new(shop_id: shop_id).get_access_token(auth_code)
  end

  def channel
    @channel ||= Channel::Shopee.create!(channel_attributes)
  end

  def channel_attributes
    @channel_attributes ||= {
      shop_id: shop_id,
      account_id: account.id,
      partner_id: partner_id,
      access_token: access_token,
      refresh_token: refresh_token,
      expires_at: expires_at
    }
  end

  def account
    @account ||= Account.find(account_id)
  end

  def shop_name
    shop_info['shop_name'] || "Shopee ##{shop_id}"
  end

  def shop_info
    @shop_info ||= Integrations::Shopee::Shop.new(shop_id: shop_id, access_token: access_token).info
  end

  def partner_id
    Integrations::Shopee::Constants.partner_id!
  end

  def access_token
    authentication_data['access_token']
  end

  def refresh_token
    authentication_data['refresh_token']
  end

  def expires_at
    authentication_data['expire_in'].to_i.seconds.from_now
  end
end
