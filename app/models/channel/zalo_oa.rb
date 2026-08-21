# == Schema Information
#
# Table name: channel_zalo_oa
#
#  id               :bigint           not null, primary key
#  access_token     :text
#  app_secret       :text             not null
#  oa_name          :string
#  oa_secret_key    :text
#  refresh_token    :text
#  token_expires_at :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :integer          not null
#  app_id           :string           not null
#  oa_id            :string           not null
#
# Indexes
#
#  index_channel_zalo_oa_on_oa_id  (oa_id) UNIQUE
#
class Channel::ZaloOa < ApplicationRecord
  include Channelable

  self.table_name = 'channel_zalo_oa'

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  if Chatwoot.encryption_configured?
    encrypts :app_secret
    encrypts :oa_secret_key
    encrypts :access_token
    encrypts :refresh_token
  end

  # Channels are created via the OAuth callback (not the generic inbox-create endpoint), so
  # oa_id is intentionally absent here; this list only governs credential rotation on update.
  EDITABLE_ATTRS = [:app_id, :app_secret, :oa_secret_key].freeze

  validates :oa_id, presence: true, uniqueness: true
  validates :app_id, presence: true
  validates :app_secret, presence: true
  validates :oa_secret_key, presence: true

  def name
    'Zalo OA'
  end

  TOKEN_REFRESH_LEEWAY = 5.minutes

  def valid_access_token
    return access_token if token_expires_at.present? && token_expires_at > Time.current + TOKEN_REFRESH_LEEWAY

    refresh_access_token!
  end

  def refresh_access_token!
    lock_manager = Redis::LockManager.new
    # Another process is already refreshing; the current token is still valid for
    # TOKEN_REFRESH_LEEWAY, so use it rather than racing for a rotated refresh token.
    return access_token unless lock_manager.lock(refresh_lock_key, 30.seconds)

    begin
      tokens = ZaloOa::Client.refresh_token(app_id: app_id, app_secret: app_secret, refresh_token: refresh_token)
      update!(
        access_token: tokens[:access_token],
        refresh_token: tokens[:refresh_token],
        token_expires_at: Time.current + tokens[:expires_in].seconds
      )
      access_token
    ensure
      lock_manager.unlock(refresh_lock_key)
    end
  end

  private

  def refresh_lock_key
    format(::Redis::Alfred::ZALO_OA_REFRESH_TOKEN_MUTEX, channel_id: id)
  end
end

Channel::ZaloOa.prepend_mod_with('Channel::ZaloOa')
