class Whatsapp::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Whatsapp' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?
    raise 'WhatsApp Cloud provider required' if channel.provider != 'whatsapp_cloud'

    # marks campaign completed so that other jobs won't pick it up
    campaign.completed!

    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)
    process_audience(audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def process_audience(audience_labels)
    contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
    Rails.logger.info "Processing #{contacts.count} contacts for campaign #{campaign.id}"

    contacts.each do |contact|
      Rails.logger.info "Processing contact: #{contact.name} (#{contact.phone_number})"

      if contact.phone_number.blank?
        Rails.logger.info "Skipping contact #{contact.name} - no phone number"
        next
      end

      # WhatsApp campaigns require template_params
      if campaign.template_params.blank?
        Rails.logger.error "Skipping contact #{contact.name} - no template_params found for WhatsApp campaign"
        next
      end

      send_whatsapp_template_message(to: contact.phone_number, contact: contact)
    end

    Rails.logger.info "Campaign #{campaign.id} processing completed"
  end

  def send_whatsapp_template_message(to:, contact:)
    template_params = campaign.template_params

    # Build template info for WhatsApp API
    template_info = {
      name: template_params['name'],
      namespace: template_params['namespace'],
      lang_code: template_params['language'],
      parameters: build_template_parameters(template_params['processed_params'] || {}, contact)
    }

    Rails.logger.info "Sending WhatsApp template message to #{to} using template: #{template_info[:name]}"
    result = channel.send_template(to, template_info)
    Rails.logger.info "WhatsApp template message sent successfully to #{to}: #{result}"
    result
  rescue StandardError => e
    Rails.logger.error "Failed to send WhatsApp template message to #{to}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
    raise e
  end

  def build_template_parameters(processed_params, _contact)
    # Convert processed_params to WhatsApp format
    # This could be enhanced to support contact variable substitution
    processed_params.map { |_key, value| { type: 'text', text: value.to_s } }
  end
end
