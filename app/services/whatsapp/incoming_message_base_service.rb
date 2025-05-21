# Mostly modeled after the intial implementation of the service based on 360 Dialog
# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/
class Whatsapp::IncomingMessageBaseService
  # Contains logs
  include ::Whatsapp::IncomingMessageServiceHelpers

  pattr_initialize [:inbox!, :params!]

  def perform
    Rails.logger.info('Performing incoming message base service')
    processed_params

    if processed_params.try(:[], :statuses).present?
      process_statuses
    elsif processed_params.try(:[], :messages).present?
      process_messages
    end
  end

  private

  def process_messages
    Rails.logger.info("Processing messages #{processed_params}")
    # We don't support reactions & ephemeral message now, we need to skip processing the message
    # if the webhook event is a reaction or an ephermal message or an unsupported message.
    update_campaign_replied_count if @processed_params.dig(:messages, 0, :context, :id)
    return if unprocessable_message_type?(message_type)

    # Multiple webhook event can be received against the same message due to misconfigurations in the Meta
    # business manager account. While we have not found the core reason yet, the following line ensure that
    # there are no duplicate messages created.
    return if find_message_by_source_id(@processed_params[:messages].first[:id]) || message_under_process?

    cache_message_source_id_in_redis
    set_contact
    return unless @contact

    set_conversation
    create_messages
    clear_message_source_id_from_redis
  end

  def process_statuses
    Rails.logger.info("Processing statuses #{processed_params}")
    update_campaign_failed_count if @processed_params[:statuses].first[:status] == 'failed'
    update_campaign_processed_count if @processed_params[:statuses].first[:status] == 'sent'
    update_campaign_read_count if @processed_params[:statuses].first[:status] == 'read'
    update_campaign_delivered_count if @processed_params[:statuses].first[:status] == 'delivered'
    return unless find_message_by_source_id(@processed_params[:statuses].first[:id])

    update_message_with_status(@message, @processed_params[:statuses].first)
    status = @processed_params[:statuses].first
  rescue ArgumentError => e
    Rails.logger.error "Error while processing whatsapp status update #{e.message}"
  end

  def update_campaign_replied_count
    context_id = @processed_params.dig(:messages, 0, :context, :id)
    return unless context_id

    # Find the campaign contact by the message ID
    campaign_contact = CampaignContact.find_by(message_id: context_id)
    return unless campaign_contact

    # Update the campaign contact status to 'replied'
    campaign_contact.update!(
      status: 'replied',
      processed_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error "Error updating campaign replied status: #{e.message}"
  end

  def update_campaign_failed_count
    # Only increment read count if status is 'read'
    status = @processed_params[:statuses].first[:status]
    id = @processed_params[:statuses].first[:id]
    return unless status == 'failed'

    # Find the campaign through the message
    campaign_contact = CampaignContact.find_by(message_id: id)

    return unless campaign_contact

    # Update the specific campaign contact status to 'read'
    error_title = @processed_params.dig(:statuses, 0, :errors, 0, :title)
    campaign_contact.update!(
      status: 'failed',
      processed_at: Time.current,
      error_message: error_title
    )

    # Find the campaign through the message
    campaign = CampaignContact.find_campaign_by_message_id(id)
    return unless campaign

    # Use atomic increment to safely update read count
    campaign.increment!(:failed_contacts_count)
  rescue StandardError => e
    Rails.logger.error "Error updating campaign failed count: #{e.message}"
  end

  def update_campaign_processed_count
    # Only increment read count if status is 'read'
    status = @processed_params[:statuses].first[:status]
    id = @processed_params[:statuses].first[:id]
    return unless status == 'sent'

    # Find the campaign through the message
    campaign_contact = CampaignContact.find_by(message_id: id)

    return unless campaign_contact

    # Update the specific campaign contact status to 'read'
    campaign_contact.update!(
      status: 'processed',
      processed_at: Time.current
    )

    # Find the campaign through the message
    campaign = CampaignContact.find_campaign_by_message_id(id)
    return unless campaign

    # Use atomic increment to safely update read count
    campaign.increment!(:processed_contacts_count)
  rescue StandardError => e
    Rails.logger.error "Error updating campaign read count: #{e.message}"
  end

  def update_campaign_read_count
    # Only increment read count if status is 'read'
    status = @processed_params[:statuses].first[:status]
    id = @processed_params[:statuses].first[:id]
    return unless status == 'read'

    # Find the campaign through the message
    campaign_contact = CampaignContact.find_by(message_id: id)

    return unless campaign_contact

    # Update the specific campaign contact status to 'read'
    campaign_contact.update!(
      status: 'read',
      processed_at: Time.current
    )

    # Find the campaign through the message
    campaign = CampaignContact.find_campaign_by_message_id(id)
    return unless campaign

    # Use atomic increment to safely update read count
    campaign.increment!(:read_count)
  rescue StandardError => e
    Rails.logger.error "Error updating campaign read count: #{e.message}"
  end

  def update_campaign_delivered_count
    # Only increment read count if status is 'read'
    status = @processed_params[:statuses].first[:status]
    id = @processed_params[:statuses].first[:id]
    return unless status == 'delivered'

    # Find the campaign through the message
    campaign_contact = CampaignContact.find_by(message_id: id)

    return unless campaign_contact

    # Update the specific campaign contact status to 'read'
    campaign_contact.update!(
      status: 'delivered',
      processed_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error "Error updating campaign delivered count: #{e.message}"
  end

  def update_message_with_status(message, status)
    message.status = status[:status]
    if status[:status] == 'failed' && status[:errors].present?
      error = status[:errors]&.first
      message.external_error = "#{error[:code]}: #{error[:title]}"
    end
    message.save!
  end

  def create_messages
    message = @processed_params[:messages].first
    log_error(message) && return if error_webhook_event?(message)

    process_in_reply_to(message)

    message_type == 'contacts' ? create_contact_messages(message) : create_regular_message(message)
  end

  def create_contact_messages(message)
    message['contacts'].each do |contact|
      create_message(contact)
      attach_contact(contact)
      @message.save!
    end
  end

  def create_regular_message(message)
    create_message(message)
    attach_files
    attach_location if message_type == 'location'
    @message.save!
  end

  def set_contact
    contact_params = @processed_params[:contacts]&.first
    return if contact_params.blank?

    waid = processed_waid(contact_params[:wa_id])

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: { name: contact_params.dig(:profile, :name), phone_number: "+#{@processed_params[:messages].first[:from]}" }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations
                                    .where.not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def attach_files
    return if %w[text button interactive location contacts].include?(message_type)

    attachment_payload = @processed_params[:messages].first[message_type.to_sym]
    @message.content ||= attachment_payload[:caption]

    attachment_file = download_attachment_file(attachment_payload)
    return if attachment_file.blank?

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  end

  def attach_location
    location = @processed_params[:messages].first['location']
    location_name = location['name'] ? "#{location['name']}, #{location['address']}" : ''
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      coordinates_lat: location['latitude'],
      coordinates_long: location['longitude'],
      fallback_title: location_name,
      external_url: location['url']
    )
  end

  def create_message(message)
    @message = @conversation.messages.build(
      content: message_content(message),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: message[:id].to_s,
      in_reply_to_external_id: @in_reply_to_external_id
    )
  end

  def attach_contact(contact)
    phones = contact[:phones]
    phones = [{ phone: 'Phone number is not available' }] if phones.blank?

    phones.each do |phone|
      @message.attachments.new(
        account_id: @message.account_id,
        file_type: file_content_type(message_type),
        fallback_title: phone[:phone].to_s
      )
    end
  end
end
