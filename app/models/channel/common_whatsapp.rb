# == Schema Information
#
# Table name: channel_common_whatsapp
#
#  id           :bigint           not null, primary key
#  phone_number :string           not null
#  token        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#
# Indexes
#
#  index_channel_common_whatsapp_on_phone_number  (phone_number) UNIQUE
#  index_channel_common_whatsapp_on_token         (token) UNIQUE
#

class Channel::CommonWhatsapp < ApplicationRecord
    include Channelable
    require 'json'

    self.table_name = 'channel_common_whatsapp'
    EDITABLE_ATTRS = [:phone_number, :token].freeze

    validates :phone_number, presence: true, uniqueness: true
    validates :token, presence: true, uniqueness: true
  
    def name
      'CommonWhatsapp'
    end

    def api_headers
      { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
    end

    def api_base_path
      "#{ENV.fetch('WPP_CONNECT_API_URL', '')}/api/#{phone_number}"
    end
  
    def send_message(target_phone_number, message)
      if message.attachments.present?
        send_attachment_message(target_phone_number, message)
      else
        send_text_message(target_phone_number, message)
      end
    end

    def on_destroy_channel
      Rails.logger.info("DESTROYING CHANNEL AND CLOSING OPENED SESSION")
      Rails.logger.info(logout_session)
      Rails.logger.info(clear_session)
    end

    private

    def send_text_message(target_phone_number, message)
      response = HTTParty.post(
        "#{api_base_path}/send-message",
        headers: api_headers,
        body: {
          phone: target_phone_number,
          message: message.content
        }.to_json
      )
  
      process_response(response)
    end

    def process_response(response)
      if response.success?
        response['response'].first['id']
      else
        Rails.logger.error response.body
        nil
      end
    end

    def logout_session
      response = HTTParty.post(
          "#{api_base_path}/logout-session",
          headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
      )
      response
    end

    def clear_session
      response = HTTParty.post(
        "#{api_base_path}/close-session",
        headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' },
        body: {
            clearSession: true
        }.to_json
      )
      response
    end
  
    def send_attachment_message(target_phone_number, message)
      attachment = message.attachments.first
      type = %w[image audio video wav].include?(attachment.file_type) ? attachment.file_type : 'document'
      caption = message.content unless %w[audio sticker].include?(type)

      request_url = "#{api_base_path}/#{type == "audio" ? "send-voice" : "send-file"}"

      response = HTTParty.post(
        request_url,
        headers: api_headers,
        body: {
          phone: target_phone_number,
          caption: caption,
          path: attachment.download_url
        }.to_json
      )
  
      process_response(response)
    end

  end
  
