class ConversationImport < ApplicationJob
  queue_as :critical

  def perform(conversation_id, previous_conversation_id)
    ActiveRecord::Base.transaction do
      populate_historical_messages(conversation_id, previous_conversation_id)
    end
  end

  private

  # rubocop:disable Metrics/AbcSize
  def populate_historical_messages(conversation_id, previous_conversation_id)
    conversation = Conversation.find(conversation_id)

    Rails.logger.info("Populating historical messages for conversation: #{conversation.id}")

    previous_messages = fetch_previous_messages(previous_conversation_id)

    previous_messages.each do |message_data|
      new_message = conversation.messages.create!(message_data[:message_attributes])
      Rails.logger.info("Created historical message: #{new_message.id}")

      message_data[:attachments].each do |attachment_data|
        new_attachment = new_message.attachments.create!(attachment_data[:attributes])
        Rails.logger.info("Created attachment for historical message: #{new_attachment.id}")

        if attachment_data[:active_storage_data]
          ActiveStorage::Attachment.create!(attachment_data[:active_storage_data].merge(record_id: new_attachment.id))
          Rails.logger.info("Created ActiveStorage attachment for historical message attachment: #{new_attachment.id}")
        end
      end
    end
  end

  # rubocop:enable Metrics/AbcSize
  def fetch_previous_messages(previous_conversation_id)
    Rails.logger.info('Fetching previous messages')
    previous_conversation = Conversation.find(previous_conversation_id)

    if previous_conversation.blank?
      Rails.logger.info('No previous conversation found')
      return []
    end

    Rails.logger.info("Found previous conversation: #{previous_conversation.id}")

    messages = fetch_messages(previous_conversation)
    Rails.logger.info("Processing #{messages.count} messages from previous conversation")

    attachments = fetch_attachments_for_messages(messages)

    build_message_data_with_attachments(messages, attachments)
  end

  def fetch_messages(conversation)
    conversation.messages
                .order(created_at: :asc)
                .reject { |msg| msg.private && msg.content.include?('Conversation with') }
  end

  def fetch_attachments_for_messages(messages)
    message_ids = messages.map(&:id)
    Attachment.where(message_id: message_ids).group_by(&:message_id)
  end

  def build_message_data_with_attachments(messages, attachments)
    messages.map do |message|
      message_data = build_message_data(message)
      message_attachments = attachments[message.id] || []
      add_attachments_to_message_data(message_data, message_attachments)
      message_data
    end
  end

  def build_message_data(message)
    Rails.logger.info("Building message data for message: #{message.id}")
    {
      message_attributes: message.attributes.except('id', 'conversation_id').merge(
        additional_attributes: (message.additional_attributes || {}).merge(
          ignore_automation_rules: true,
          disable_notifications: true
        )
      ),
      attachments: []
    }
  end

  def add_attachments_to_message_data(message_data, attachments)
    attachments.each do |attachment|
      attachment_data = build_attachment_data(attachment)
      message_data[:attachments] << attachment_data
      Rails.logger.info("Processed attachment: #{attachment.id}")
    end
  end

  def build_attachment_data(attachment)
    attachment_data = { attributes: attachment.attributes.except('id', 'message_id') }
    add_active_storage_data(attachment, attachment_data)
    attachment_data
  end

  def add_active_storage_data(attachment, attachment_data)
    Rails.logger.info("Adding ActiveStorage data for attachment: #{attachment.id}")
    return unless attachment.file.attached?

    attachment_data[:active_storage_data] = {
      name: attachment.file.filename,
      record_type: 'Attachment',
      blob_id: attachment.file.blob.id,
      created_at: Time.zone.now
    }
    Rails.logger.info("Added ActiveStorage data for attachment: #{attachment.id}")
  end
end
