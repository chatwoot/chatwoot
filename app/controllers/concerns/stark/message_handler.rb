require 'open-uri'

module Stark
  module MessageHandler
    extend ActiveSupport::Concern

    def handle_response(response)
      return unless response_valid?(response)

      if response['content'].present? || (response['attachments'].is_a?(Array) && response['attachments'].any?)
        create_bot_response_message(current_conversation, response['content'], response['attachments'])
      end
      process_action(event_data[:message], response['action']) if response['action'].present?
    end

    def create_bot_response_message(conversation, content, attachments = nil)
      create_text_message(conversation, content) if content.present?
      create_attachment_messages(conversation, attachments) if attachments.is_a?(Array)
    end

    def response_valid?(response)
      attachments_present = response['attachments'].is_a?(Array) && response['attachments'].any?
      response.is_a?(Hash) && (response['content'].present? || response['action'].present? || attachments_present)
    end

    private

    def create_text_message(conversation, content)
      conversation.messages.create!(
        content: content,
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        sender: agent_bot
      )
    end

    def create_attachment_messages(conversation, attachments)
      attachments.each do |attachment|
        url = attachment.is_a?(Hash) ? (attachment['url'] || attachment[:url]) : attachment
        content = attachment.is_a?(Hash) ? (attachment['content'] || attachment[:content]) : nil
        next if url.blank?

        file = URI.open(url)
        filename = File.basename(URI.parse(url).path)

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: filename,
          content_type: file.content_type
        )

        message = conversation.messages.new(
          content: content,
          message_type: :outgoing,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          sender: agent_bot
        )

        message.attachments.new(
          account_id: message.account_id,
          external_url: url,
          file: blob
        )

        message.save!
      end
    end
  end
end
