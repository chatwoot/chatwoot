class ConversationImport < ApplicationJob
  queue_as :critical

  def perform(conversation_id, previous_conversation_id)
    # Store the mapping for later use
    @old_to_new_message_id_map = {}
    @import_completed_at = nil

    ActiveRecord::Base.transaction do
      populate_historical_messages(conversation_id, previous_conversation_id)
      update_all_references(conversation_id)
      @import_completed_at = Time.current
    end

    # After transaction commits, catch any messages created during the transaction commit window
    # This handles the race condition where messages are created while the job is queued/running
    update_late_arrivals(conversation_id) if @import_completed_at && @old_to_new_message_id_map.present?
  end

  private

  # rubocop:disable Metrics/AbcSize
  def populate_historical_messages(conversation_id, previous_conversation_id)
    conversation = Conversation.find(conversation_id)

    Rails.logger.info("Populating historical messages for conversation: #{conversation.id}")

    previous_messages = fetch_previous_messages(previous_conversation_id)

    previous_messages.each do |message_data|
      old_message_id = message_data[:old_message_id]
      new_message = conversation.messages.create!(message_data[:message_attributes])
      Rails.logger.info("Created historical message: #{new_message.id} from old message: #{old_message_id}")

      # Store the mapping of old message ID to new message ID
      @old_to_new_message_id_map[old_message_id] = new_message.id

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
      old_message_id: message.id,
      message_attributes: message.attributes.except('id', 'conversation_id').merge(
        additional_attributes: (message.additional_attributes || {}).merge(
          ignore_automation_rules: true,
          disable_notifications: true,
          skip_ensure_in_reply_to: true # Skip callback to preserve old in_reply_to values
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

  # Update in_reply_to references for all messages in the conversation
  # This runs inside the transaction after importing messages
  def update_all_references(conversation_id)
    Rails.logger.info('Updating in_reply_to references for all messages')
    conversation = Conversation.find(conversation_id)

    conversation.messages
                .where.not(content_attributes: nil)
                .find_each(batch_size: 100) do |message|
      update_message_references(message, conversation)
    end

    Rails.logger.info('Finished updating in_reply_to references')
  end

  # Catch messages created during the transaction commit window
  # Uses timestamp filtering to avoid reprocessing messages already handled
  def update_late_arrivals(conversation_id)
    Rails.logger.info('Running late arrivals update pass')
    conversation = Conversation.find(conversation_id)

    conversation.messages
                .where('created_at >= ?', @import_completed_at)
                .where.not(content_attributes: nil)
                .find_each do |message|
      update_message_references(message, conversation)
    end

    Rails.logger.info('Finished late arrivals update pass')
  end

  # Single method to update a message's in_reply_to references
  # Handles the mapping from old conversation message IDs to new ones
  def update_message_references(message, conversation)
    old_in_reply_to_id = message.content_attributes['in_reply_to']
    return if old_in_reply_to_id.blank?

    # Check if this in_reply_to ID is in our mapping (from the old conversation)
    new_in_reply_to_id = @old_to_new_message_id_map[old_in_reply_to_id]
    return if new_in_reply_to_id.blank?

    # Skip if already updated
    return if message.content_attributes['in_reply_to'] == new_in_reply_to_id

    # Find the referenced message in the new conversation
    referenced_message = conversation.messages.find_by(id: new_in_reply_to_id)
    return if referenced_message.blank?

    Rails.logger.info("Updating message #{message.id}: in_reply_to from #{old_in_reply_to_id} to #{new_in_reply_to_id}")

    # CRITICAL: Must reassign entire hash for JSON column type to detect changes
    updated_attributes = message.content_attributes.dup
    updated_attributes['in_reply_to'] = new_in_reply_to_id
    updated_attributes['in_reply_to_external_id'] = referenced_message.source_id if referenced_message.source_id.present?
    message.content_attributes = updated_attributes
    message.save!
  end
end
