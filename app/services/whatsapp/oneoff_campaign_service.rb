class Whatsapp::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    validate_campaign!
    prepare_campaign_contacts(extract_audience_labels)
    process_audience
    campaign.completed!
    process_audience(extract_audience_labels)
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

    channel.send_template(contact.phone_number, {
                            name: name,
                            namespace: namespace,
                            lang_code: lang_code,
                            parameters: processed_parameters
                          }, nil)

    campaign_contact.mark_as_sent!
    Rails.logger.info "Successfully sent message to #{contact.phone_number}"
  rescue StandardError => e
    error_message = "#{e.class.name}: #{e.message}"
    Rails.logger.error "Failed to send WhatsApp template message to #{contact.phone_number}: #{error_message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
    campaign_contact.mark_as_failed!(error_message)
  end
end
