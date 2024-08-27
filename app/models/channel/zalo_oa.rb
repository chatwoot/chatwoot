# == Schema Information
#
# Table name: channel_zalo_oa
#
#  id              :bigint           not null, primary key
#  expires_in      :integer          not null
#  oa_access_token :string           not null
#  refresh_token   :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#  oa_id           :string           not null
#
# Indexes
#
#  index_channel_zalo_oa_on_oa_id  (oa_id) UNIQUE
#

class Channel::ZaloOa < ApplicationRecord
  include Channelable

  self.table_name = 'channel_zalo_oa'
  EDITABLE_ATTRS = [:oa_access_token, :refresh_token, :expires_in].freeze

  validates :oa_access_token, presence: true, length: { maximum: 2048 }
  validates :refresh_token, presence: true, length: { maximum: 2048 }
  validates :expires_in, presence: true
  validates :account_id, presence: true
  validates :oa_id, presence: true
  validates :oa_id, uniqueness: true

  def name
    'ZaloOa'
  end

  def send_message(user_id, message, access_token)
    # check attachments to send first
    message.attachments.each do |attachment|
      response = send_attachment(user_id, attachment, access_token)
      return response unless (response['error']).zero? && message.content
    end

    body = message_body(user_id, message.content)
    body[:message][:quote_message_id] = message.content_attributes[:in_reply_to_external_id] if message.content_attributes[:in_reply_to_external_id]
    send_message_cs(body, access_token)
  end

  def refresh_access_token(channel)
    response = refresh_post(channel.refresh_token)
    if response['access_token']
      channel.update!(oa_access_token: response['access_token'], refresh_token: response['refresh_token'],
                      expires_in: response['expires_in'])
    end
    response
  end

  def send_message_cs(body, access_token)
    HTTParty.post(
      url_message_cs,
      headers: { 'Content-Type' => 'application/json', 'access_token' => access_token },
      body: body.to_json
    )
  end

  private

  def url_message_cs
    'https://openapi.zalo.me/v3.0/oa/message/cs'
  end

  def url_refresh_token
    'https://oauth.zaloapp.com/v4/oa/access_token'
  end

  def url_upload_file
    'https://openapi.zalo.me/v2.0/oa/upload/file'
  end

  def url_upload_image
    'https://openapi.zalo.me/v2.0/oa/upload/image'
  end

  def send_attachment(user_id, attachment, access_token)
    is_image = attachment.file_type == 'image'
    url_upload = is_image ? url_upload_image : url_upload_file
    return unless (response = upload_file_to_zalo_api(url_upload, attachment, access_token)).code == '200'

    data = JSON.parse(response.body)
    return data unless (data['error']).zero?

    body = is_image ? image_body(user_id, data['data']['attachment_id']) : attachment_body(user_id, data['data']['token'])
    send_message_cs(body, access_token)
  end

  # unknown issue with HTTParty so changed to Net::HTTP with success
  def upload_file_to_zalo_api(url_upload, attachment, access_token)
    url = URI.parse(url_upload)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url.path)
    request['access_token'] = access_token
    request.content_type = 'multipart/form-data'
    request.set_form([
                       ['file', attachment.file.download, { filename: attachment.file.filename.to_s }]
                     ], 'multipart/form-data')

    http.request(request)
  end

  def refresh_post(refresh_token)
    HTTParty.post(
      url_refresh_token,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded', 'secret_key' => ENV.fetch('ZALO_APP_SECRET', nil) },
      body: refresh_body(refresh_token)
    )
  end

  def refresh_body(refresh_token)
    {
      refresh_token: refresh_token,
      app_id: ENV.fetch('ZALO_APP_ID', nil),
      grant_type: 'refresh_token'
    }
  end

  def attachment_body(user_id, file_token)
    {
      recipient: { user_id: user_id },
      message: {
        attachment: {
          type: 'file',
          payload: {
            token: file_token
          }
        }
      }
    }
  end

  def image_body(user_id, attachment_id)
    {
      recipient: { user_id: user_id },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'media',
            elements: [{
              media_type: 'image',
              attachment_id: attachment_id
            }]
          }
        }
      }
    }
  end

  def message_body(user_id, message_content)
    {
      recipient: { user_id: user_id },
      message: { text: message_content }
    }
  end
end
