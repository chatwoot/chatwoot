# == Schema Information
#
# Table name: channel_sms
#
#  id              :bigint           not null, primary key
#  phone_number    :string           not null
#  provider        :string           default("default")
#  provider_config :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#
# Indexes
#
#  index_channel_sms_on_phone_number  (phone_number) UNIQUE
#

class Channel::Sms < ApplicationRecord
  include Channelable

  self.table_name = 'channel_sms'
  EDITABLE_ATTRS = [:phone_number, { provider_config: {} }].freeze
  CONFIG_KEYS = %w[account_id application_id api_key api_secret client_id client_secret].freeze
  OAUTH_REQUIRED_KEYS = %w[account_id application_id client_id client_secret].freeze
  LEGACY_REQUIRED_KEYS = %w[account_id application_id api_key api_secret].freeze

  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config

  def name
    'Sms'
  end

  # all this should happen in provider service . but hack mode on
  def api_base_path
    'https://messaging.bandwidth.com/api/v2'
  end

  def send_message(contact_number, message)
    body = message_body(contact_number, message.outgoing_content)
    body['media'] = message.attachments.map(&:download_url) if message.attachments.present?

    send_to_bandwidth(body, message)
  end

  def send_text_message(contact_number, message_content)
    body = message_body(contact_number, message_content)
    send_to_bandwidth(body)
  end

  def oauth?
    provider_config.is_a?(Hash) && provider_config.keys.intersect?(%w[client_id client_secret])
  end

  def media_download_options
    return { headers: authorization_headers } if oauth?

    { http_basic_authentication: provider_config.values_at('api_key', 'api_secret') }
  end

  private

  def validate_provider_config
    config = provider_config
    required_keys = oauth? ? OAUTH_REQUIRED_KEYS : LEGACY_REQUIRED_KEYS
    return if config.is_a?(Hash) && (required_keys - config.keys).empty? && (config.keys - CONFIG_KEYS).empty? &&
              valid_provider_config_values?

    errors.add(:provider_config, I18n.t('errors.bandwidth.invalid_configuration'))
  end

  def valid_provider_config_values?
    provider_config.values.all? { |value| value.is_a?(String) && value.present? }
  end

  def message_body(contact_number, message_content)
    {
      'to' => contact_number,
      'from' => phone_number,
      'text' => message_content,
      'applicationId' => provider_config['application_id']
    }
  end

  def send_to_bandwidth(body, message = nil)
    response = HTTParty.post(
      "#{api_base_path}/users/#{provider_config['account_id']}/messages",
      **authentication_options,
      body: body.to_json
    )

    if response.success?
      response.parsed_response['id']
    else
      handle_error(response.parsed_response['description'], message)
      nil
    end
  rescue CustomExceptions::Bandwidth::AuthenticationError => e
    handle_error(e.message, message)
    nil
  end

  def handle_error(description, message)
    Rails.logger.error("[#{account_id}] Error sending SMS: #{description}")
    return if message.blank?

    # https://dev.bandwidth.com/apis/messaging-apis/messaging/#tag/Messages/operation/createMessage
    message.external_error = description
    message.status = :failed
    message.save!
  end

  def authentication_options
    headers = { 'Content-Type' => 'application/json' }
    return { headers: headers.merge(authorization_headers) } if oauth?

    { headers: headers, basic_auth: { username: provider_config['api_key'], password: provider_config['api_secret'] } }
  end

  def authorization_headers
    { 'Authorization' => "Bearer #{Sms::BandwidthTokenService.new(config: provider_config).token}" }
  end
end
