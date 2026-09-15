class Channel::WechatKf < ApplicationRecord
  include Channelable

  self.table_name = 'channel_wechat_kf'
  EDITABLE_ATTRS = [].freeze

  belongs_to :wechat_kf_integration
  validates :open_kfid, presence: true, uniqueness: true
  validate :integration_belongs_to_account

  def name
    'WeChat Customer Service'
  end

  private

  def integration_belongs_to_account
    return if wechat_kf_integration.blank? || wechat_kf_integration.account_id == account_id

    errors.add(:wechat_kf_integration, 'must belong to the same account')
  end
end
