require 'open-uri'

module Stark
  module MessageHandler
    extend ActiveSupport::Concern

    def handle_response(response)
      return unless response_valid?(response)

      if response['content'].present? || (response['attachments'].is_a?(Array) && response['attachments'].any?)
        create_bot_response_message(current_conversation, response['content'], response['attachments'], response['metadata'])
      end
      process_action(event_data[:message], response['action']) if response['action'].present?
    end

    def create_bot_response_message(conversation, content, attachments = nil, metadata = {})
      if instagram_channel?(conversation) && attachments.is_a?(Array) && attachments.any?

        # 1. Send main content only once
        if content.present?
          conversation.messages.create!(
            content: content,
            message_type: :outgoing,
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            sender: agent_bot,
            metadata: metadata
          )
        end

        # 2. For each attachment: image then title
        attachments.each do |attachment|
          url = attachment.is_a?(Hash) ? (attachment['url'] || attachment[:url]) : attachment
          title = attachment.is_a?(Hash) ? (attachment['content'] || attachment[:content]) : nil
          next if url.blank?

          file = URI.open(url)
          filename = File.basename(URI.parse(url).path)

          blob = ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: filename,
            content_type: file.content_type
          )

          # (a) Image message (no content)
          image_message = conversation.messages.create!(
            message_type: :outgoing,
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            sender: agent_bot,
            additional_attributes: { 'sent_image': true }
          )
          image_message.attachments.create!(
            account_id: image_message.account_id,
            external_url: url,
            file: blob
          )
          image_message.save!

          # (b) Title message (text only), after a small delay
          next unless title.present?

          conversation.messages.create!(
            content: title,
            message_type: :outgoing,
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            sender: agent_bot
          )
        end

      else
        # Non-Instagram: default behavior
        create_text_message(conversation, content, metadata) if content.present?
        create_attachment_messages(conversation, attachments) if attachments.is_a?(Array)
      end
    end

    def response_valid?(response)
      attachments_present = response['attachments'].is_a?(Array) && response['attachments'].any?
      response.is_a?(Hash) && (response['content'].present? || response['action'].present? || attachments_present)
    end

    private

    def create_text_message(conversation, content, metadata = {})
      conversation.messages.create!(
        content: content,
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        sender: agent_bot,
        metadata: metadata
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

    def instagram_channel?(conversation)
      conversation.inbox.platform_name == 'Instagram'
    end
  end
end
