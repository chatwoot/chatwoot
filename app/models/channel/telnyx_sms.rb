# == Schema Information
#
# Table name: channel_telnyx_sms
#
#  id           :bigint           not null, primary key
#  phone_number :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#
# Indexes
#
#  index_channel_telnyx_sms_on_phone_number  (phone_number) UNIQUE
#

class Channel::TelnyxSms < ApplicationRecord
  include Channelable

  self.table_name = 'channel_telnyx_sms'

  PROVIDER_CONFIG_ATTRS = %i[api_key messaging_profile_id].freeze
  EDITABLE_ATTRS = [:phone_number, { provider_config: PROVIDER_CONFIG_ATTRS }].freeze

  has_one :telnyx_sms_config, dependent: :destroy, inverse_of: :channel_telnyx_sms, autosave: true

  validates :phone_number, presence: true, uniqueness: true
  validates :telnyx_sms_config, presence: true

  def name
    'Telnyx SMS'
  end

  def send_message(contact_number, message)
    body = message_body(contact_number, message.outgoing_content)
    body[:media_urls] = message.attachments.map(&:download_url) if message.attachments.present?
    send_to_telnyx(body, message)
  end

  def send_text_message(contact_number, message_content)
    send_to_telnyx(message_body(contact_number, message_content))
  end

  def provider_config
    return {} unless telnyx_sms_config

    {
      'api_key' => telnyx_sms_config.api_key,
      'messaging_profile_id' => telnyx_sms_config.messaging_profile_id
    }
  end

  def provider_config=(config)
    attributes = config.to_h.with_indifferent_access.slice(*PROVIDER_CONFIG_ATTRS)
    telnyx_sms_config ? telnyx_sms_config.assign_attributes(attributes) : build_telnyx_sms_config(attributes)
  end

  private

  def message_body(contact_number, text)
    {
      from: phone_number,
      to: contact_number,
      text: text,
      messaging_profile_id: telnyx_sms_config.messaging_profile_id
    }
  end

  def send_to_telnyx(body, message = nil)
    if Rails.env.development? && ENV.fetch('TELNYX_MOCK_ENABLED', 'false') == 'true'
      mock_message_id = "mock-telnyx-#{SecureRandom.uuid}"
      Rails.logger.info("[#{account_id}] Mocked Telnyx message #{mock_message_id}")
      return mock_message_id
    end

    response = HTTParty.post(
      'https://api.telnyx.com/v2/messages',
      headers: {
        'Authorization' => "Bearer #{telnyx_sms_config.api_key}",
        'Content-Type' => 'application/json'
      },
      body: body.to_json
    )

    return response.parsed_response.dig('data', 'id') if response.success?

    handle_error(response, message)
    nil
  end

  def handle_error(response, message)
    error_detail = response.parsed_response.dig('errors', 0, 'detail') || response.body
    Rails.logger.error("[#{account_id}] Telnyx error: #{error_detail}")
    return if message.blank?

    message.external_error = error_detail
    message.status = :failed
    message.save!
  end
end

Channel::TelnyxSms.prepend_mod_with('Channel::TelnyxSms')
