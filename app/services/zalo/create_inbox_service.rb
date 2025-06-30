require 'base64'
require 'digest'

class Zalo::CreateInboxService
  REQUIRED_PARAMS = %i[code oa_id account_id state code_challenge].freeze

  class Error < StandardError; end

  pattr_initialize :params

  def perform
    validate_params!
    validate_code_challenge!
    validate_auth_code!
    validate_access_token!
    create_inbox

    @inbox || raise(Error, 'Inbox creation failed')
  end

  private

  attr_reader :auth, :oa_info

  def validate_params!
    return if REQUIRED_PARAMS.all? { |key| params[key].present? }

    raise Error, "Missing required parameters: #{REQUIRED_PARAMS.join(', ')}"
  end

  def validate_code_challenge!
    expected_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(params[:state]), padding: false)
    return if expected_challenge == params[:code_challenge]

    raise Error, 'Invalid code challenge'
  end

  def validate_auth_code!
    @auth = Integrations::Zalo::Auth.new.verify(
      code: params[:code],
      code_verifier: params[:state]
    )
    raise(Error, @auth['error_description'] || 'Failed to authenticate with Zalo') if @auth['error_description'].present?
  end

  def validate_access_token!
    @oa_info = Integrations::Zalo::OfficialAccount.new(@auth['access_token']).detail
  rescue Integrations::Zalo::Client::AuthError => e
    raise(Error, @oa_info['message'] || 'Failed to fetch OA info')
  end

  def account
    @account ||= Account.find(params[:account_id])
  end

  def create_inbox
    @inbox = Inbox.find_or_initialize_by(channel: channel, account: account)
    return unless @inbox.new_record?

    @inbox.name = oa_info.dig('name').presence || oa_info.dig('oa_alias') || oa_info.dig('oa_id')
    @inbox.save!
    @inbox.avatar.attach(io: URI.open(oa_info.dig('avatar')), filename: 'logo.jpg', content_type: 'image/jpeg')
  end

  def channel
    @channel = Channel::Zalo.find_or_initialize_by(account: account, oa_id: oa_info.dig('oa_id'))
    @channel.assign_attributes(channel_attributes)
    @channel.save!
    @channel
  end

  def channel_attributes
    {
      access_token: auth['access_token'],
      refresh_token: auth['refresh_token'],
      expires_at: auth['expires_in'].to_i.seconds.from_now,
      oa_id: oa_info.dig('oa_id'),
      meta: oa_info.slice('description', 'oa_alias', 'is_verified', 'oa_type', 'cate_name', 'num_follower')
    }
  end
end
