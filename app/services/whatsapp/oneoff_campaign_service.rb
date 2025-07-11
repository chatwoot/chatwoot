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

  def validate_campaign!
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Whatsapp' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?
    raise 'WhatsApp Cloud provider required' if channel.provider != 'whatsapp_cloud'
  end

  def extract_audience_labels
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    campaign.account.labels.where(id: audience_label_ids).pluck(:title)
  end

  def process_contact(contact)
    Rails.logger.info "Processing contact: #{contact.name} (#{contact.phone_number})"

    if contact.phone_number.blank?
      Rails.logger.info "Skipping contact #{contact.name} - no phone number"
      return
    end

    if campaign.template_params.blank?
      Rails.logger.error "Skipping contact #{contact.name} - no template_params found for WhatsApp campaign"
      return
    end

    send_whatsapp_template_message(to: contact.phone_number)
  end

  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
    Rails.logger.info "Processing #{contacts.count} contacts for campaign #{campaign.id}"

    contacts.each { |contact| process_contact(contact) }

    Rails.logger.info "Campaign #{campaign.id} processing completed"
  end

  def send_whatsapp_template_message(to:)
    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: campaign.template_params
    )

    name, namespace, lang_code, processed_parameters = processor.call

    return if name.blank?

    channel.send_template(to, {
                            name: name,
                            namespace: namespace,
                            lang_code: lang_code,
                            parameters: processed_parameters
                          })

  rescue StandardError => e
    Rails.logger.error "Failed to send WhatsApp template message to #{to}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
    raise e
  end
end
