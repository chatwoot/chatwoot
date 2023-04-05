class Conversations::ForwardMessageJob < ApplicationJob
  queue_as :default

  def perform(payload)
    @user = User.find(payload[:user_id])
    @account = Account.find(payload[:account_id])
    @message = Message.find(payload[:message_id])
    @contacts = payload[:contacts]

    Rails.logger.info @message
    return if @contacts.blank?

    @contacts.each do |contact_id|
      contact = @account.contacts.find(contact_id)
      Rails.logger.info contact
      contact_conversation = forward_conversation(contact)
      Rails.logger.info contact_conversation
      msg = contact_conversation.messages.build(message_params)
      Rails.logger.info msg
      process_attachment(msg)
      msg.save!
    rescue StandardError => e
      Rails.logger.error e
      raise e
    end
  end

  private

  def message_params
    {
      account_id: @message.account_id,
      inbox_id: @message.inbox_id,
      content: @message.content,
      message_type: :outgoing,
      sender: @user
    }
  end

  def create_contact_inbox(contact)
    ::ContactInboxBuilder.new(
      contact: contact,
      inbox: @message.inbox,
      hmac_verified: true
    ).perform
  end

  def conversation_params(contact)
    contact_inbox = create_contact_inbox(contact)
    Rails.logger.info contact_inbox
    {
      contact_id: contact.id,
      contact_inbox_id: contact_inbox.id,
      account_id: @message.account_id,
      inbox_id: @message.inbox_id,
      assignee_id: @user.id
    }
  end

  def forward_conversation(contact)
    contact_conversation = @account.conversations.find_by!(contact_id: contact.id, inbox: @message.inbox_id)
  rescue StandardError => e
    contact_conversation = ::Conversation.create!(conversation_params(contact))
  end

  def process_attachment(msg)
    Rails.logger.info @message.attachments
    return if @message.attachments.blank?

    @message.attachments.each do |attachment|
      Rails.logger.info attachment
      attach_file(msg, attachment)
      attach_location(msg, attachment)
      attach_contact(msg, attachment)
    end
  end

  def attach_file(msg, attachment)
    return if %w[image audio video file].include?(attachment.file_type) == false
    msg.attachments.new(
      account_id: attachment.account_id,
      file_type: attachment.file_type,
      file: attachment.file.blob
    )
  end

  def attach_location(msg, attachment)
    return if attachment.file_type != "location"
    msg.attachments.new(
      account_id: attachment.account_id,
      file_type: attachment.file_type,
      coordinates_lat: attachment.coordinates_lat,
      coordinates_long: attachment.coordinates_long,
      fallback_title: attachment.fallback_title,
      external_url: attachment.external_url
    )
  end

  def attach_contact(msg, attachment)
    return if attachment.file_type != "contact"
    msg.attachments.new(
      account_id: attachment.account_id,
      file_type: attachment.file_type,
      fallback_title: attachment.fallback_title
    )
  end
end
