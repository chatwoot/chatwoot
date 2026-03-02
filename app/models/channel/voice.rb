# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_voice
#
#  id                    :bigint           not null, primary key
#  phone_number          :string           not null
#  provider              :string           default("twilio"), not null
#  provider_config       :jsonb            not null
#  account_id            :integer          not null
#  additional_attributes :jsonb            default({})
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_channel_voice_on_phone_number  (phone_number) UNIQUE
#  index_channel_voice_on_account_id    (account_id)
#

class Channel::Voice < ApplicationRecord
  include Channelable
  include Rails.application.routes.url_helpers

  self.table_name = 'channel_voice'

  validates :phone_number, presence: true, uniqueness: true
  validates :provider_config, presence: true

  EDITABLE_ATTRS = %i[phone_number provider provider_config additional_attributes].freeze

  def name
    'Voice'
  end

  # Twilio REST client for outbound calls / status queries
  def twilio_client
    if api_key_sid.present?
      Twilio::REST::Client.new(api_key_sid, api_key_secret, account_sid)
    else
      Twilio::REST::Client.new(account_sid, auth_token)
    end
  end

  # Verify incoming Twilio webhook signature
  def verify_twilio_signature(url, params, signature)
    validator = Twilio::Security::RequestValidator.new(auth_token)
    validator.validate(url, params, signature)
  end

  # Provider config accessors
  def account_sid
    provider_config&.dig('account_sid')
  end

  def auth_token
    provider_config&.dig('auth_token')
  end

  def api_key_sid
    provider_config&.dig('api_key_sid')
  end

  def api_key_secret
    provider_config&.dig('api_key_secret')
  end

  def twiml_app_sid
    provider_config&.dig('twiml_app_sid')
  end

  # Webhook URLs used by Twilio configuration
  def voice_call_webhook_url
    "#{ENV.fetch('FRONTEND_URL', '')}/saas/api/v1/voice/twilio/incoming"
  end

  def voice_status_webhook_url
    "#{ENV.fetch('FRONTEND_URL', '')}/saas/api/v1/voice/twilio/status"
  end
end
