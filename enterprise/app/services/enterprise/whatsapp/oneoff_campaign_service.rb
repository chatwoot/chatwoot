module Enterprise::Whatsapp::OneoffCampaignService
  private

  def process_contacts(contacts)
    contacts.each do |contact|
      recipient = recipient_for(contact)
      process_recipient(recipient) if recipient.queued?
    end
  end

  def recipient_for(contact)
    campaign.campaign_recipients.find_or_create_by!(contact: contact) do |recipient|
      recipient.account = campaign.account
      recipient.inbox = campaign.inbox
    end
  end

  def process_recipient(recipient)
    contact = recipient.contact
    Rails.logger.info "Processing contact: #{contact.name} (#{contact.phone_number})"

    destination, destination_error = campaign_destination(contact)
    if destination.blank?
      recipient.mark_skipped!(destination_error)
      return
    end

    if campaign.template_params.blank?
      Rails.logger.error "Skipping contact #{contact.name} - no template_params found for WhatsApp campaign"
      recipient.mark_skipped!('Template parameters are missing')
      return
    end

    processed_template_params = process_liquid_template_params(contact)
    if processed_template_params.nil?
      recipient.mark_skipped!('Template parameters could not be resolved')
      return
    end

    recipient.update!(message_content: rendered_message_content(contact))

    send_whatsapp_template_message(recipient: recipient, to: destination, template_params: processed_template_params)
  end

  def rendered_message_content(contact)
    Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)
  end

  def send_whatsapp_template_message(recipient:, to:, template_params:)
    return if authentication_template_blocked?(recipient, to, template_params)

    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: template_params
    )

    name, namespace, lang_code, processed_parameters = processor.call

    if name.blank?
      recipient.mark_skipped!('Template name could not be resolved')
      return
    end

    save_recipient_destination(recipient, to)
    source_id = channel.send_template(to, template_info(name, namespace, lang_code, processed_parameters), nil)

    update_recipient_from_provider_response(recipient, source_id)
  rescue StandardError => e
    Rails.logger.error "Failed to send WhatsApp template message to #{to}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
    recipient.mark_failed!(message: e.message)
    # continue processing remaining contacts
    nil
  end

  def save_recipient_destination(recipient, destination)
    source_id = destination.delete_prefix('+')
    normalized_source_id = Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(source_id, :cloud)
    contact_inbox = recipient.contact.contact_inboxes.find_by(inbox: inbox, source_id: normalized_source_id)
    contact_inbox ||= recipient.contact.contact_inboxes.create_or_find_by!(inbox: inbox, source_id: source_id)
    recipient.update!(contact_inbox: contact_inbox)
  end

  def template_info(name, namespace, lang_code, processed_parameters)
    {
      name: name,
      namespace: namespace,
      lang_code: lang_code,
      parameters: processed_parameters
    }
  end

  def authentication_template_blocked?(campaign_recipient, recipient, params)
    error = Whatsapp::AuthenticationTemplateGuard.new(channel: channel, recipient: recipient, template_params: params).error
    return false unless error

    campaign_recipient.mark_skipped!(error)
    true
  end

  def update_recipient_from_provider_response(recipient, source_id)
    if source_id.present?
      recipient.mark_sent!(source_id)
    else
      recipient.mark_failed!(channel.last_provider_error || { message: 'WhatsApp provider did not return a message id' })
    end
  end
end
