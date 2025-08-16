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

  def process_contact(contact)
    campaign_message = create_campaign_message(contact)

    return handle_contact_validation_errors(campaign_message, contact) unless contact_valid?(contact)

    whatsapp_message_id = send_whatsapp_template_message(to: contact.phone_number)
    update_campaign_message_status(campaign_message, whatsapp_message_id)
  end

  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
    Rails.logger.info "Processing #{contacts.count} contacts for campaign #{campaign.id}"

    contacts.each { |contact| process_contact(contact) }

    Rails.logger.info "Campaign #{campaign.id} processing completed"
  end

  def contact_valid?(contact)
    contact.phone_number.present? && campaign.template_params.present?
  end

  def handle_contact_validation_errors(campaign_message, contact)
    if contact.phone_number.blank?
      campaign_message.update!(status: 'failed', error_code: 'missing_phone_number',
                               error_description: 'Contact has no phone number')
    elsif campaign.template_params.blank?
      campaign_message.update!(status: 'failed', error_code: 'missing_template_params',
                               error_description: 'No template_params found for WhatsApp campaign')
    end
  end

  def update_campaign_message_status(campaign_message, whatsapp_message_id)
    if whatsapp_message_id
      campaign_message.update!(message_id: whatsapp_message_id, status: 'sent', sent_at: Time.current)
    else
      campaign_message.update!(status: 'failed', error_description: 'Failed to send WhatsApp template message')
    end
  end

  def create_campaign_message(contact)
    campaign.campaign_messages.create!(
      contact: contact,
      status: 'pending'
    )
  end

  def send_whatsapp_template_message(to:)
    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: campaign.template_params
    )

    name, namespace, lang_code, processed_parameters = processor.call

    return nil if name.blank?

    channel.send_template(to, {
                            name: name,
                            namespace: namespace,
                            lang_code: lang_code,
                            parameters: processed_parameters
                          }, nil)

  rescue StandardError => e
    Rails.logger.error "Failed to send WhatsApp template message to #{to}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
    # continue processing remaining contacts
    nil
  end
end
