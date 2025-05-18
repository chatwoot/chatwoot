# == Schema Information
#
# Table name: channel_whatsapp_zapi
#
#  id              :bigint           not null, primary key
#  api_url         :string           not null
#  phone_number    :string           not null
#  provider_config :jsonb
#  security_token  :string
#  token           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  instance_id     :string           not null
#
# Indexes
#
#  index_channel_whatsapp_zapi_on_account_id    (account_id)
#  index_channel_whatsapp_zapi_on_phone_number  (phone_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Channel::WhatsappZapi < ApplicationRecord
  include Channelable

  self.table_name = 'channel_whatsapp_zapi'
  EDITABLE_ATTRS = [:phone_number, :instance_id, :token, :api_url, :security_token, { provider_config: {} }].freeze

  validates :phone_number, presence: true, uniqueness: true
  validates :instance_id, presence: true
  validates :token, presence: true
  validates :api_url, presence: true
  validates :security_token, presence: true

  def name
    'WhatsApp Z-API'
  end

  def send_message(to:, message:, type: 'text', media_url: nil)
    require 'net/http'
    require 'uri'
    require 'json'
    url = URI.parse("#{api_url}/instances/#{instance_id}/token/#{token}/send-#{type}")
    payload = { phone: to }
    if type == 'text'
      payload[:message] = message
    elsif %w[image audio video document].include?(type)
      payload[:url] = media_url
      payload[:caption] = message if message.present?
    end
    Rails.logger.info "[ZAPI OUTBOUND] Enviando para Z-API: url=#{url} payload=#{payload.to_json}"
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    req = Net::HTTP::Post.new(url.path, {
                                'Content-Type' => 'application/json',
                                'Client-Token' => security_token
                              })
    req.body = payload.to_json
    response = http.request(req)
    Rails.logger.info "[ZAPI OUTBOUND] Resposta Z-API: status=#{response.code} body=#{response.body}"
    response
  end
end
