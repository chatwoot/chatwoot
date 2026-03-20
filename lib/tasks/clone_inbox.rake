# frozen_string_literal: true

namespace :inbox do # rubocop:disable Metrics/BlockLength
  desc 'Clone all messages from a source inbox to a destination inbox'
  task :clone_messages, %i[source_inbox_id destination_inbox_id] => :environment do |_task, args| # rubocop:disable Metrics/BlockLength
    source_inbox_id = args[:source_inbox_id]
    destination_inbox_id = args[:destination_inbox_id]

    if source_inbox_id.blank? || destination_inbox_id.blank?
      puts 'Usage: rails inbox:clone_messages[<source_inbox_id>,<destination_inbox_id>]'
      next
    end

    if source_inbox_id == destination_inbox_id
      puts "ERROR: Source and destination inbox IDs are the same (ID: #{source_inbox_id}). Please provide different IDs."
      next
    end

    source_inbox = Inbox.find(source_inbox_id)
    destination_inbox = Inbox.find(destination_inbox_id)

    if source_inbox.account_id != destination_inbox.account_id
      puts "ERROR: Source and destination inboxes are in different accounts (Source Account ID: #{source_inbox.account_id}, " \
           "Destination Account ID: #{destination_inbox.account_id})"
      next
    end

    puts "Cloning messages from '#{source_inbox.name}' (ID: #{source_inbox.id}) to '#{destination_inbox.name}' (ID: #{destination_inbox.id})..."

    old_to_new_contact_inbox = {}
    old_to_new_conversation = {}
    cloned_messages_count = 0
    failed_messages_count = 0

    puts 'Cloning contacts and contact inboxes...'
    ActiveRecord::Base.transaction do
      source_inbox.contact_inboxes.includes(:contact).find_each do |contact_inbox|
        existing_contact_inbox = destination_inbox.contact_inboxes.find_by(source_id: contact_inbox.source_id)
        if existing_contact_inbox
          old_to_new_contact_inbox[contact_inbox.id] = existing_contact_inbox.id
          next
        end

        contact_attrs = contact_inbox.contact.attributes.except('id', 'created_at', 'updated_at', 'account_id')

        new_contact_inbox = ContactInboxWithContactBuilder.new(
          source_id: contact_inbox.source_id,
          inbox: destination_inbox,
          contact_attributes: contact_attrs
        ).perform
        new_contact = new_contact_inbox.contact

        if contact_inbox.contact.respond_to?(:label_list) && contact_inbox.contact.label_list.present?
          new_contact.label_list = contact_inbox.contact.label_list
        end

        new_contact.custom_attributes = contact_inbox.contact.custom_attributes.dup if contact_inbox.contact.custom_attributes.present?

        new_contact.save!
        old_to_new_contact_inbox[contact_inbox.id] = new_contact_inbox.id
      end
    end
    puts "Cloned #{old_to_new_contact_inbox.count} contact inboxes."

    puts 'Cloning conversations...'
    ActiveRecord::Base.transaction do
      source_inbox.conversations.includes(:conversation_participants, :csat_survey_response).find_each do |conversation|
        target_contact_inbox_id = old_to_new_contact_inbox[conversation.contact_inbox_id]
        next unless target_contact_inbox_id

        existing_conversation = destination_inbox.conversations.find_by(
          contact_inbox_id: target_contact_inbox_id,
          created_at: conversation.created_at
        )

        if existing_conversation
          old_to_new_conversation[conversation.id] = existing_conversation.id
          next
        end

        new_conversation_attrs = conversation.attributes.except('id', 'display_id', 'updated_at', 'uuid')
        new_conversation_attrs['inbox_id'] = destination_inbox.id
        new_conversation_attrs['contact_inbox_id'] = target_contact_inbox_id

        new_conversation = destination_inbox.conversations.create!(new_conversation_attrs)
        old_to_new_conversation[conversation.id] = new_conversation.id

        if conversation.label_list.present?
          new_conversation.label_list = conversation.label_list
          new_conversation.save!
        end

        new_conversation.update!(custom_attributes: conversation.custom_attributes.dup) if conversation.custom_attributes.present?

        conversation.conversation_participants.each do |conversation_participant|
          participant_attrs = conversation_participant.attributes.except('id', 'created_at', 'updated_at')
          participant_attrs['conversation_id'] = new_conversation.id
          new_conversation.conversation_participants.create!(participant_attrs)
        end

        if (csat_response = conversation.csat_survey_response)
          new_conversation.create_csat_survey_response!(csat_response.attributes.except('id', 'conversation_id', 'updated_at'))
        end
      end
    end
    puts "Cloned #{old_to_new_conversation.count} conversations."

    puts 'Cloning messages...'
    source_inbox.messages.includes(:attachments).find_in_batches(batch_size: 1000) do |message_batch| # rubocop:disable Metrics/BlockLength
      ActiveRecord::Base.transaction do # rubocop:disable Metrics/BlockLength
        message_batch.each do |original_message| # rubocop:disable Metrics/BlockLength
          new_conv_id = old_to_new_conversation[original_message.conversation_id]
          next unless new_conv_id

          existing_message = if original_message.source_id.present?
                               Message.find_by(
                                 conversation_id: new_conv_id,
                                 source_id: original_message.source_id
                               )
                             else
                               Message.find_by(
                                 conversation_id: new_conv_id,
                                 created_at: original_message.created_at,
                                 content: original_message.content
                               )
                             end

          if existing_message
            cloned_messages_count += 1
            next
          end

          message_attrs = original_message.attributes.except('id', 'updated_at')
          message_attrs['conversation_id'] = new_conv_id
          message_attrs['inbox_id'] = destination_inbox.id

          new_message = destination_inbox.messages.new(message_attrs)

          begin
            new_message.skip_message_flooding_validation = true
            new_message.save!
            cloned_messages_count += 1
            original_message.attachments.each do |attachment|
              new_message.attachments.create!(
                file_type: attachment.file_type,
                account_id: destination_inbox.account_id,
                file: attachment.file.blob
              )
            end
          rescue StandardError => e
            failed_messages_count += 1
            puts "Failed to clone message ID: #{original_message.id}. Errors: #{e.message}"
          end
        end
      end
      print "Progress: Cloned: #{cloned_messages_count} | Failed: #{failed_messages_count}\r"
    end

    puts "\nCloning complete."
    puts "Successfully cloned #{cloned_messages_count} messages."
    puts "Failed to clone #{failed_messages_count} messages."
  end
end
