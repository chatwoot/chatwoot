class Whatsapp::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    validate_campaign!
    validate_template_integrity!
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

    name, namespace, lang_code, processed_parameters, components = processor.call

    return if name.blank?

    payload = {
      name: name,
      namespace: namespace,
      lang_code: lang_code,
      parameters: processed_parameters
    }
    payload[:components] = components if components.present?

    channel.send_template(to, payload)

  rescue StandardError => e
    Rails.logger.error "Failed to send WhatsApp template message to #{to}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
    # continue processing remaining contacts
    nil
  end

  def validate_template_integrity!
    params = campaign.template_params || {}
    template = find_approved_template(params)
    raise 'Template is not approved or not found for the selected language' if template.blank?

    # Validate BODY placeholders vs processed_params
    processed = params['processed_params'] || {}
    body = template['components']&.find { |c| c['type'] == 'BODY' }
    if body && body['text'].is_a?(String)
      # supports named {{var}} or numeric {{1}}
      required_keys = body['text'].scan(/{{\s*([^}]+)\s*}}/).flatten
      if required_keys.any?
        # For numeric placeholders, ensure count
        if required_keys.all? { |k| k.match?(/^\d+$/) }
          raise 'Missing required template variables' if processed.values.compact.map(&:to_s).reject(&:empty?).length < required_keys.length
        else
          missing = required_keys.reject { |k| processed.key?(k) && processed[k].to_s.strip.present? }
          raise "Missing required template variables: #{missing.join(', ')}" if missing.any?
        end
      end
    end

    # Validate header media urls once per campaign
    header = params['header'] || {}
    header_type = header['type']&.to_s&.downcase
    return unless %w[image video document].include?(header_type)

    url = header['url']
    raise 'Header media URL is required' if url.blank?

    begin
      response = HTTParty.head(url, timeout: 5)
      raise 'Header media URL is not reachable' unless response.success?
    rescue StandardError
      raise 'Header media URL is not reachable'
    end
  end

  def find_approved_template(params)
    channel.message_templates&.find do |t|
      t['name'] == params['name'] &&
        (t['language'] == params['language'] || t['language'] == params['language']&.to_s) &&
        t['status']&.downcase == 'approved'
    end
  end
end
