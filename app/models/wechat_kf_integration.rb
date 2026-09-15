class WechatKfIntegration < ApplicationRecord
  belongs_to :account
  has_many :channels, class_name: 'Channel::WechatKf', dependent: :destroy

  encrypts :corp_secret, :callback_token, :encoding_aes_key if Chatwoot.encryption_configured?

  validates :corp_id, :corp_secret, :callback_token, :encoding_aes_key, presence: true
  validates :corp_id, uniqueness: true
  validates :callback_token, length: { maximum: 32 }
  validates :encoding_aes_key, format: { with: /\A[A-Za-z0-9]{43}\z/ }

  def callback_url
    "#{ENV.fetch('FRONTEND_URL')}/webhooks/wechat_kf/#{corp_id}"
  end
end
