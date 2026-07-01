# == Schema Information
#
# Table name: channel_zalo_oa
#
#  id            :bigint           not null, primary key
#  oa_id         :string           not null
#  access_token  :string           not null
#  refresh_token :string
#  account_id    :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_channel_zalo_oa_on_oa_id  (oa_id) UNIQUE
#

class Channel::ZaloOa < ApplicationRecord
  include Channelable

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  if Chatwoot.encryption_configured?
    encrypts :access_token
    encrypts :refresh_token
  end

  self.table_name = 'channel_zalo_oa'
  EDITABLE_ATTRS = [:oa_id, :access_token, :refresh_token].freeze

  validates :oa_id, uniqueness: true, presence: true
  validates :access_token, presence: true

  def name
    'Zalo OA'
  end

  def api_base_url
    'https://openapi.zalo.me/v2.0'
  end

  def send_message_api_url
    "#{api_base_url}/oa/message"
  end

  def get_user_info_api_url(_user_id)
    "#{api_base_url}/oa/getuserinfo"
  end

  def send_message(user_id, message_text, attachments: [])
    payload = build_message_payload(user_id, message_text, attachments)
    response = HTTParty.post(
      send_message_api_url,
      headers: api_headers,
      body: payload.to_json,
      query: { access_token: access_token }
    )
    handle_response(response)
  end

  private

  def api_headers
    {
      'Content-Type' => 'application/json'
    }
  end

  def build_message_payload(user_id, message_text, attachments)
    payload = {
      recipient: {
        user_id: user_id
      },
      message: {
        text: message_text
      }
    }

    # Add attachments if present
    payload[:message][:attachment] = build_attachment_payload(attachments) if attachments.any?

    payload
  end

  def build_attachment_payload(attachments)
    attachments.first(1).map do |attachment|
      {
        type: attachment_type(attachment),
        payload: {
          url: attachment.download_url
        }
      }
    end
  end

  def attachment_type(attachment)
    case attachment.file_type
    when 'image'
      'image'
    when 'video'
      'video'
    when 'file', 'audio'
      'file'
    else
      'image'
    end
  end

  def handle_response(response)
    parsed_response = response.parsed_response
    return parsed_response if response.success? && parsed_response['error'] == 0

    error_message = parsed_response['message'] || 'Unknown error'
    raise StandardError, "Zalo API Error: #{error_message}"
  end
end
