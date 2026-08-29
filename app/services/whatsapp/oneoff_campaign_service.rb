class Whatsapp::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    validate_campaign!
    process_audience(extract_audience_labels)
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
    return if whatsapp_cloud_channel? || twilio_whatsapp_channel?

    raise 'WhatsApp Cloud provider required'
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

  def process_contact(contact)
    Rails.logger.info "Processing contact: #{contact.name} (#{contact.phone_number})"

    recipient, recipient_error = campaign_destination(contact)
    if recipient.blank?
      Rails.logger.warn "Skipping campaign recipient contact_id=#{contact.id}: #{recipient_error}"
      return
    end

    if campaign.template_params.blank?
      Rails.logger.error "Skipping contact #{contact.name} - no template_params found for WhatsApp campaign"
      return
    end

    processed_template_params = process_liquid_template_params(contact)
    return if processed_template_params.nil?

    send_whatsapp_template_message(to: recipient, template_params: processed_template_params)
  end

  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
    Rails.logger.info "Processing #{contacts.count} contacts for campaign #{campaign.id}"

    contacts.each { |contact| process_contact(contact) }

    Rails.logger.info "Campaign #{campaign.id} processing completed"
  end

  def process_liquid_template_params(contact)
    liquid_processor = Whatsapp::LiquidTemplateProcessorService.new(campaign: campaign, contact: contact)
    processed_template_params = liquid_processor.process_template_params(campaign.template_params)

    Rails.logger.info "Skipping contact #{contact.name} - liquid variables resolved to blank values" if processed_template_params.nil?

    processed_template_params
  rescue StandardError => e
    Rails.logger.error "Failed to process liquid template params for contact #{contact.name}: #{e.message}"
    nil
  end

  def send_whatsapp_template_message(to:, template_params:)
    return if authentication_template_blocked?(to, template_params)

    submit_template(to, template_params)
  rescue StandardError => e
    Rails.logger.error "Failed to send WhatsApp template message to #{to}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
    # continue processing remaining contacts
    nil
  end

  def submit_template(to, template_params)
    return submit_twilio_template(to, template_params) if twilio_whatsapp_channel?

    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: template_params
    )

    name, namespace, lang_code, processed_parameters = processor.call

    raise 'Template name could not be resolved' if name.blank?

    channel.send_template(to, {
                            name: name,
                            namespace: namespace,
                            lang_code: lang_code,
                            parameters: processed_parameters
                          }, nil)
  end

  def submit_twilio_template(to, template_params)
    content_sid, content_variables = Twilio::TemplateProcessorService.new(channel: channel, template_params: template_params).call
    raise 'Template could not be resolved' if content_sid.blank?

    send_params = { to: to, content_sid: content_sid }.merge(channel.send(:send_message_from))
    send_params[:content_variables] = content_variables.to_json if content_variables.present?
    send_params[:status_callback] = channel.send(:twilio_delivery_status_index_url)

    channel.client.messages.create(**send_params)&.sid
  end

  def authentication_template_blocked?(recipient, params)
    error = Whatsapp::AuthenticationTemplateGuard.new(channel: channel, recipient: recipient, template_params: params).error
    return false unless error

    Rails.logger.warn "Skipping BSUID campaign recipient: #{error}"
    true
  end

  def campaign_destination(contact)
    return [phone_recipient(contact.phone_number), nil] if contact.phone_number.present?

    bsuid_recipients = bsuid_recipients_for(contact)
    return [bsuid_recipients.first, nil] if bsuid_recipients.one?
    return [nil, 'Phone number and BSUID are missing'] if bsuid_recipients.empty?

    [nil, 'Multiple WhatsApp identities found; refusing to choose a destination']
  end

  def bsuid_recipients_for(contact)
    contact.contact_inboxes.where(inbox_id: inbox.id).pluck(:source_id).select do |source_id|
      source_id.to_s.delete_prefix('whatsapp:').match?(RegexHelper::WHATSAPP_BSUID_REGEX)
    end.uniq
  end

  def phone_recipient(phone_number)
    return phone_number unless twilio_whatsapp_channel?

    "whatsapp:#{phone_number.to_s.delete_prefix('whatsapp:')}"
  end

  def whatsapp_cloud_channel?
    channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
  end

  def twilio_whatsapp_channel?
    channel.is_a?(Channel::TwilioSms) && channel.whatsapp?
  end
end

Whatsapp::OneoffCampaignService.prepend_mod_with('Whatsapp::OneoffCampaignService')
