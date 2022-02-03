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

  validates :phone_number, presence: true, uniqueness: true
  # before_save :validate_provider_config

  def name
    'Sms'
  end

  # all this should happen in provider service . but hack mode on
  def api_base_path
    'https://messaging.bandwidth.com/api/v2'
  end

  # Extract later into provider Service
  def send_message(phone_number, message)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message.content)
    end
  end

  def send_text_message(contact_number, message)
    response = HTTParty.post(
      "#{api_base_path}/users/#{provider_config['account_id']}/messages",
      basic_auth: bandwidth_auth,
      headers: { 'Content-Type' => 'application/json' },
      body: {
        'to' => contact_number,
        'from' => phone_number,
        'text' => message,
        'applicationId' => provider_config['application_id']
      }.to_json
    )

    response.success? ? response.parsed_response['id'] : nil
  end

  private

  def send_attachment_message(phone_number, message)
    # fix me
  end

  def bandwidth_auth
    { username: provider_config['api_key'], password: provider_config['api_secret'] }
  end

  # Extract later into provider Service
  # let's revisit later
  def validate_provider_config
    response = HTTParty.post(
      "#{api_base_path}/users/#{provider_config['account_id']}/messages",
      basic_auth: bandwidth_auth,
      headers: { 'Content-Type': 'application/json' }
    )
    errors.add(:provider_config, 'error setting up') unless response.success?
  end
end
