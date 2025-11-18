class Whatsapp::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    validate_campaign!
    prepare_campaign_contacts(extract_audience_labels)
    process_audience
    campaign.completed!
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def validate_campaign_type!
    raise "Invalid campaign #{campaign.id}" unless whatsapp_campaign? && campaign.one_off?
  end

  def whatsapp_campaign?
    campaign.inbox.inbox_type == 'Whatsapp'
  end

  def validate_campaign_status!
    raise 'Completed Campaign' if campaign.completed?
  end

  def validate_provider!
    raise 'WhatsApp Cloud provider required' if channel.provider != 'whatsapp_cloud'
  end

  def validate_feature_flag!
    raise 'WhatsApp campaigns feature not enabled' unless campaign.account.feature_enabled?(:whatsapp_campaign)
  end

  def validate_campaign!
    validate_campaign_type!
    validate_campaign_status!
    validate_provider!
    validate_feature_flag!
  end

  def extract_audience_labels
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    campaign.account.labels.where(id: audience_label_ids).pluck(:title)
  end

  def prepare_campaign_contacts(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
    Rails.logger.info "Preparing #{contacts.count} contacts for campaign #{campaign.id}"

    contacts.each do |contact|
      campaign.campaign_contacts.find_or_create_by!(contact: contact)
    end
  end

  def process_contact(campaign_contact)
    contact = campaign_contact.contact
    Rails.logger.info "Processing contact: #{contact.name} (#{contact.phone_number})"

    if contact.phone_number.blank?
      Rails.logger.info "Skipping contact #{contact.name} - no phone number"
      campaign_contact.mark_as_skipped!('No phone number')
      return
    end

    # Validate phone number format early
    normalized_phone = contact.phone_number.to_s.gsub(/\D/, '')
    unless normalized_phone.match?(/^\d{1,15}$/)
      error_msg = "Invalid phone format: '#{contact.phone_number}' (normalized: '#{normalized_phone}', length: #{normalized_phone.length})"
      Rails.logger.warn "Skipping contact #{contact.name} - #{error_msg}"
      campaign_contact.mark_as_skipped!(error_msg)
      return
    end

    if campaign.template_params.blank?
      Rails.logger.error "Skipping contact #{contact.name} - no template_params found for WhatsApp campaign"
      campaign_contact.mark_as_skipped!('No template params')
      return
    end

    send_whatsapp_template_message(contact: contact, campaign_contact: campaign_contact)
  end

  def process_audience
    Rails.logger.info "Processing #{campaign.campaign_contacts.count} contacts for campaign #{campaign.id}"

    campaign.campaign_contacts.pending.each { |campaign_contact| process_contact(campaign_contact) }

    Rails.logger.info "Campaign #{campaign.id} processing completed"
  end

  def send_whatsapp_template_message(contact:, campaign_contact:)
    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: campaign.template_params
    )

    name, namespace, lang_code, processed_parameters = processor.call

    if name.blank?
      error_msg = "Template '#{campaign.template_params['name']}' could not be processed or not found in WhatsApp Business API"
      campaign_contact.mark_as_failed!(error_msg)
      return
    end

    # Send the template message via WhatsApp API FIRST (before any DB operations)
    message_id = channel.send_template(contact.phone_number, {
                                         name: name,
                                         namespace: namespace,
                                         lang_code: lang_code,
                                         parameters: processed_parameters
                                       }, nil)

    # Verify send was successful
    raise 'Failed to send template message - no message_id returned' unless message_id.present?

    # Mark as sent IMMEDIATELY after successful WhatsApp API call to prevent duplicate sends on retry
    campaign_contact.mark_as_sent!
    Rails.logger.info "WhatsApp message sent successfully to #{contact.phone_number}, message_id: #{message_id}"

    # Now try to create DB records - if this fails, message was already sent and marked
    begin
      contact_inbox = find_or_create_contact_inbox(contact)
      conversation = find_or_create_conversation(contact_inbox)
      create_outgoing_message(conversation, contact, name, message_id)
      Rails.logger.info "Message record created in conversation #{conversation.id}"
    rescue StandardError => db_error
      # Log DB error but DON'T mark as failed since message was already sent successfully
      Rails.logger.error "Message sent but failed to create DB records for #{contact.phone_number}: #{db_error.class.name}: #{db_error.message}"
      Rails.logger.error "Backtrace: #{db_error.backtrace.first(3).join('\n')}"
      # Message is already marked as sent, so no retry will occur
    end
  rescue StandardError => e
    error_message = "#{e.class.name}: #{e.message}"
    Rails.logger.error "Failed to send WhatsApp template message to #{contact.phone_number}: #{error_message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
    campaign_contact.mark_as_failed!(error_message)
  end

  def find_or_create_contact_inbox(contact)
    # Normalize phone number to WhatsApp format (remove '+' and keep only digits)
    normalized_phone = contact.phone_number.to_s.gsub(/\D/, '')

    contact_inbox = inbox.contact_inboxes.find_by(source_id: normalized_phone)
    return contact_inbox if contact_inbox

    # Create new contact_inbox if not found
    ContactInboxBuilder.new(
      contact: contact,
      inbox: inbox,
      source_id: normalized_phone
    ).perform
  end

  def find_or_create_conversation(contact_inbox)
    # Follow the same logic as incoming messages
    conversation = if inbox.lock_to_single_conversation
                     contact_inbox.conversations.last
                   else
                     contact_inbox.conversations.where.not(status: :resolved).last
                   end

    return conversation if conversation

    # Create new conversation
    Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id
    )
  end

  def create_outgoing_message(conversation, contact, template_name, message_id)
    # Generate the rendered template content
    rendered_content = render_template_content(template_name, contact)

    message = conversation.messages.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :outgoing,
      content: rendered_content,
      sender: nil,
      source_id: message_id,
      status: :sent,
      content_attributes: {
        campaign_id: campaign.id,
        template_name: template_name
      }
    )

    # Attach media if present in template (image, video, document)
    attach_template_media(message, template_name)

    message
  end

  def render_template_content(template_name, _contact)
    # Find the template from channel's message_templates
    template = find_template(template_name)
    return "Template: #{template_name}" if template.blank?

    # Extract body text from template components
    body_component = template['components']&.find { |c| c['type'] == 'BODY' }
    return "Template: #{template_name}" if body_component.blank?

    template_text = body_component['text']
    return template_text if template_text.blank?

    # Replace variables with actual values from processed_params
    rendered_text = template_text.dup
    processed_params = campaign.template_params.dig('processed_params', 'body') || {}

    # Replace {{1}}, {{2}}, etc. with actual values
    processed_params.each do |key, value|
      rendered_text.gsub!("{{#{key}}}", value.to_s)
    end

    rendered_text
  end

  def attach_template_media(message, _template_name)
    # Get header media from template_params
    header_params = campaign.template_params.dig('processed_params', 'header')
    return if header_params.blank?

    media_url = header_params['media_url']
    media_type = header_params['media_type']
    return if media_url.blank? || media_type.blank?

    # Map WhatsApp media types to Chatwoot file types
    file_type = case media_type.downcase
                when 'image' then :image
                when 'video' then :video
                when 'document' then :file
                else :file
                end

    # Download and attach the media
    begin
      downloaded_file = Down.download(media_url)
      message.attachments.create!(
        account_id: message.account_id,
        file_type: file_type,
        file: {
          io: downloaded_file,
          filename: header_params['media_name'] || File.basename(media_url),
          content_type: downloaded_file.content_type
        }
      )
    rescue StandardError => e
      Rails.logger.error "Failed to attach media to message #{message.id}: #{e.message}"
    end
  end

  def find_template(template_name)
    @template_cache ||= channel.message_templates.index_by { |t| "#{t['name']}:#{t['language']}" }
    @template_cache["#{template_name}:#{campaign.template_params['language']}"]
  end
end
