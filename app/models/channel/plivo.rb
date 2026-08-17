# == Schema Information
#
# Table name: channel_plivo
#
#  id              :bigint           not null, primary key
#  phone_number    :string           not null
#  provider_config :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#
# Indexes
#
#  index_channel_plivo_on_phone_number  (phone_number) UNIQUE
#

class Channel::Plivo < ApplicationRecord
  include Channelable

  self.table_name = 'channel_plivo'
  EDITABLE_ATTRS = [:phone_number, { provider_config: {} }].freeze

  validates :phone_number, presence: true, uniqueness: true

  def name
    'Plivo'
  end

  def messaging_url
    "https://api.plivo.com/v1/Account/#{provider_config['auth_id']}/Message/"
  end

  def send_message(contact_number, message)
    body = message_body(contact_number, message.outgoing_content)
    if message.attachments.present?
      body[:type] = 'mms'
      body[:media_urls] = message.attachments.map(&:download_url)
    end

    send_to_plivo(body, message)
  end

  def send_text_message(contact_number, message_content)
    send_to_plivo(message_body(contact_number, message_content))
  end

  private

  def message_body(contact_number, message_content)
    {
      src: phone_number,
      dst: contact_number,
      text: message_content
    }
  end

  def send_to_plivo(body, message = nil)
    response = HTTParty.post(
      messaging_url,
      basic_auth: plivo_auth,
      headers: { 'Content-Type' => 'application/json' },
      body: body.to_json
    )

    if response.success?
      response.parsed_response['message_uuid']&.first
    else
      handle_error(response, message)
      nil
    end
  end

  def handle_error(response, message)
    error = response.parsed_response.is_a?(Hash) ? response.parsed_response['error'] : response.body
    Rails.logger.error("[#{account_id}] Error sending Plivo message: #{error}")
    return if message.blank?

    message.external_error = error
    message.status = :failed
    message.save!
  end

  def plivo_auth
    { username: provider_config['auth_id'], password: plivo_token }
  end

  def plivo_token
    provider_config['auth_token']
  end
end
