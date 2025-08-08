require 'open-uri'

module Stark
  module MessageHandler
    extend ActiveSupport::Concern

    def handle_response(response)
      return unless response_valid?(response)

      create_bot_response_message(current_conversation, response['content'], response['attachments']) if response['content'].present?
      process_action(event_data[:message], response['action']) if response['action'].present?
    end

    def create_bot_response_message(conversation, content, attachment_urls = nil)
      create_text_message(conversation, content) if content.present?
      create_attachment_messages(conversation, attachment_urls) if attachment_urls.is_a?(Array)
    end

    def response_valid?(response)
      response.is_a?(Hash) && (response['content'].present? || response['action'].present?)
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

    def create_attachment_messages(conversation, urls)
      urls.each do |url|
        file = URI.open(url)
        filename = File.basename(URI.parse(url).path)

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: filename,
          content_type: file.content_type
        )

        message = conversation.messages.new(
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
