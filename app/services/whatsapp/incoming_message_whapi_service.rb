# frozen_string_literal: true

class Whatsapp::IncomingMessageWhapiService
  pattr_initialize [:inbox!, :params!]

  def perform
    return if message_already_processed?

    # For group messages, process both incoming and outgoing
    # For individual messages, skip outgoing (from_me)
    return if params['from_me'] && !group_message?

    set_contact
    return unless @contact

    ActiveRecord::Base.transaction do
      set_conversation
      create_message
    end
  end

  private

  def message_already_processed?
    inbox.messages.exists?(source_id: params['id'])
  end

  def set_contact
    chat_id = params['chat_id'] || params['from']
    is_group = chat_id.to_s.include?('@g.us')

    if is_group
      setup_group_contact(chat_id)
    else
      setup_individual_contact(chat_id)
    end
  end

  def setup_group_contact(chat_id)
    # For groups, use the full chat_id as source_id
    # Find existing contact_inbox for this group
    @contact_inbox = inbox.contact_inboxes.find_by(source_id: chat_id)

    unless @contact_inbox
      Rails.logger.error "[WHATSAPP LIGHT] Group contact_inbox not found for chat_id: #{chat_id}"
      return
    end

    @contact = @contact_inbox.contact
  end

  def setup_individual_contact(chat_id)
    phone_number = extract_phone_number(chat_id)
    contact_name = params['from_name'] || params.dig('chat', 'name') || phone_number

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: phone_number,
      inbox: inbox,
      contact_attributes: {
        name: contact_name,
        phone_number: "+#{phone_number}"
      }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    # For group messages, find the whatsapp_group conversation
    # For individual messages, find the default conversation
    @conversation = if group_message?
                      find_or_build_group_conversation
                    else
                      find_or_build_individual_conversation
                    end
    @conversation.save!
  end

  def find_or_build_group_conversation
    # Find existing group conversation for this contact_inbox
    conversation = ::Conversation.find_by(
      contact_inbox_id: @contact_inbox.id,
      conversation_type: :whatsapp_group
    )

    conversation || build_conversation(conversation_type: :whatsapp_group)
  end

  def find_or_build_individual_conversation
    ::Conversation.find_by(conversation_params) || build_conversation
  end

  def build_conversation(additional_params = {})
    ::Conversation.new(conversation_params.merge(
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    ).merge(additional_params))
  end

  def conversation_params
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def group_message?
    chat_id = params['chat_id'] || params['from']
    chat_id.to_s.include?('@g.us')
  end

  def create_message
    @message = @conversation.messages.create!(message_params)
    attach_files if attachment_present?
    attach_location if location_present?
    @message
  end

  def message_params
    base_params = {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: params['from_me'] ? :outgoing : :incoming,
      content: message_content,
      source_id: params['id'],
      sender: message_sender,
      external_created_at: params['timestamp'] ? Time.zone.at(params['timestamp']) : Time.current
    }

    # For outgoing messages without a real sender, add external sender info for display
    if params['from_me'] && message_sender.nil?
      base_params[:additional_attributes] = {
        external_sender_name: ENV.fetch('WHATSAPP_ADMIN_NAME', 'Nauto Assistant'),
        external_sender_type: 'whatsapp_admin'
      }
    end

    base_params
  end

  def message_sender
    phone = extract_phone_number(params['from'])
    formatted_phone = format_phone_number(phone)

    # Try to find a user (agent) by phone number first
    # This handles both outgoing messages (from_me=true) and group messages from agents (from_me=false)
    user = inbox.account.users.find { |u| format_phone_number(u.phone_number) == formatted_phone }
    return user if user

    # If from_me is true but no user found, it might be the admin channel
    # If from_me is false, it's a contact message
    @contact unless params['from_me']
  end

  def message_content
    case message_type
    when 'text'
      params.dig('text', 'body') || params['body']
    when 'image', 'video', 'audio', 'document', 'voice'
      params.dig(message_type, 'caption') || ''
    when 'location'
      "Location: #{params.dig('location', 'name') || 'Shared location'}"
    when 'contact', 'contacts'
      "Contact: #{params.dig('contacts', 0, 'name', 'formatted_name') || 'Shared contact'}"
    else
      ''
    end
  end

  def message_type
    params['type'] || 'text'
  end

  def attachment_present?
    %w[image video audio document voice sticker].include?(message_type)
  end

  def location_present?
    message_type == 'location'
  end

  def attach_files
    media_data = params[message_type]
    return unless media_data

    media_url = media_data['link'] || media_data['url']
    return unless media_url

    attachment_params = {
      remote_file_url: media_url,
      file_type: file_type_from_message_type,
      account_id: @conversation.account_id
    }

    attachment = @message.attachments.new(attachment_params)
    attachment.file.attach(io: Down.download(media_url), filename: filename_from_media_data(media_data))
    attachment.save!
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP LIGHT] Attachment processing error: #{e.message}"
  end

  def attach_location
    location = params['location']
    return unless location

    @message.content_attributes = {
      latitude: location['latitude'],
      longitude: location['longitude'],
      name: location['name'],
      address: location['address']
    }
    @message.save!
  end

  def file_type_from_message_type
    case message_type
    when 'image' then :image
    when 'video' then :video
    when 'audio', 'voice' then :audio
    when 'document', 'sticker' then :file
    else :file
    end
  end

  def filename_from_media_data(media_data)
    media_data['filename'] || media_data['caption'] || "#{message_type}-#{Time.current.to_i}"
  end

  def extract_phone_number(chat_id)
    # Whapi format: "1234567890@s.whatsapp.net" or "1234567890-1234567890@g.us" (group)
    chat_id.to_s.split('@').first.split('-').first
  end

  def format_phone_number(phone)
    # Remove the + if exists and leave only numbers
    phone.to_s.gsub(/[^0-9]/, '')
  end
end
