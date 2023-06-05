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

    # def get_telegram_profile_image(user_id)
    #   # get profile image from telegram
    #   response = HTTParty.get("#{telegram_api_url}/getUserProfilePhotos", query: { user_id: user_id })
    #   return nil unless response.success?
  
    #   photos = response.parsed_response.dig('result', 'photos')
    #   return if photos.blank?
  
    #   get_telegram_file_path(photos.first.last['file_id'])
    # end
  
    # def get_telegram_file_path(file_id)
    #   response = HTTParty.get("#{telegram_api_url}/getFile", query: { file_id: file_id })
    #   return nil unless response.success?
  
    #   "https://api.telegram.org/file/bot#{bot_token}/#{response.parsed_response['result']['file_path']}"
    # end
  
    def send_message(target_phone_number, message)
      # response = message_request(message.conversation[:additional_attributes]['chat_id'], message.content, reply_markup(message))
      send_text_message(target_phone_number, message)
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
  
    # def reply_markup(message)
    #   return unless message.content_type == 'input_select'
  
    #   {
    #     one_time_keyboard: true,
    #     inline_keyboard: message.content_attributes['items'].map do |item|
    #       [{
    #         text: item['title'],
    #         callback_data: item['value']
    #       }]
    #     end
    #   }.to_json
    # end
  
    # def send_attachments(message)
    #   send_message(message) unless message.content.nil?
  
    #   telegram_attachments = []
    #   message.attachments.each do |attachment|
    #     telegram_attachment = {}
  
    #     case attachment[:file_type]
    #     when 'audio'
    #       telegram_attachment[:type] = 'audio'
    #     when 'image'
    #       telegram_attachment[:type] = 'photo'
    #     when 'file'
    #       telegram_attachment[:type] = 'document'
    #     end
    #     telegram_attachment[:media] = attachment.download_url
    #     telegram_attachments << telegram_attachment
    #   end
  
    #   response = attachments_request(message.conversation[:additional_attributes]['chat_id'], telegram_attachments)
    #   response.parsed_response['result'].first['message_id'] if response.success?
    # end
  
    # def attachments_request(chat_id, attachments)
    #   HTTParty.post("#{telegram_api_url}/sendMediaGroup",
    #                 body: {
    #                   chat_id: chat_id,
    #                   media: attachments.to_json
    #                 })
    # end
  
    # def message_request(chat_id, text, reply_markup = nil)
    #   HTTParty.post("#{telegram_api_url}/sendMessage",
    #                 body: {
    #                   chat_id: chat_id,
    #                   text: text,
    #                   reply_markup: reply_markup
    #                 })
    # end
  end
  
