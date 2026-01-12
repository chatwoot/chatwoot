class Whatsapp::OneoffCampaignService
  pattr_initialize [:campaign!]

  def perform
    validate_campaign!
    # Mark campaign completed immediately to prevent duplicate job pickups
    campaign.completed!
    execute_delivery
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

  def execute_delivery
    contacts = fetch_audience_contacts
    report = initialize_delivery_report(contacts.count)

    Rails.logger.info "Processing #{contacts.count} contacts for campaign #{campaign.id}"
    contacts.each { |contact| process_contact_with_tracking(contact, report) }
    finalize_delivery(report)
  end

  def fetch_audience_contacts
    audience_labels = extract_audience_labels
    campaign.account.contacts.tagged_with(audience_labels, any: true)
  end

  def extract_audience_labels
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    campaign.account.labels.where(id: audience_label_ids).pluck(:title)
  end

  def initialize_delivery_report(total_count)
    campaign.create_delivery_report!(provider: channel.provider, status: 'running', total: total_count, started_at: Time.current)
  end

  def process_contact_with_tracking(contact, report)
    Rails.logger.info "Processing contact: #{contact.name} (#{contact.phone_number})"

    return record_skip_error(report, contact, 'No phone number') if contact.phone_number.blank?
    return record_skip_error(report, contact, 'No template params') if campaign.template_params.blank?

    send_and_track(contact, report)
  rescue StandardError => e
    handle_processing_error(report, contact, e)
  end

  def record_skip_error(report, contact, reason)
    Rails.logger.info "Skipping contact #{contact.name} - #{reason}"
    report.failed += 1
    report.record_error(code: nil, message: reason, details: "Contact #{contact.name}: #{reason}")
  end

  def handle_processing_error(report, contact, error)
    Rails.logger.error "Failed to process contact #{contact.name}: #{error.message}"
    Rails.logger.error "Backtrace: #{error.backtrace.first(5).join('\n')}"
    report.failed += 1
    report.record_error(code: nil, message: "Processing error: #{error.class.name}", details: error.message)
  end

  def send_and_track(contact, report)
    template_data = prepare_template_data(contact)
    return record_template_error(report) if template_data[:name].blank?

    result = channel.send_template_with_result(contact.phone_number, template_data)
    record_send_result(report, contact, result)
  end

  def prepare_template_data(contact)
    personalized_params = process_liquid_variables(campaign.template_params, contact)
    processor = Whatsapp::TemplateProcessorService.new(channel: channel, template_params: personalized_params)
    name, namespace, lang_code, processed_parameters = processor.call
    { name: name, namespace: namespace, lang_code: lang_code, parameters: processed_parameters }
  end

  def record_template_error(report)
    report.failed += 1
    report.record_error(code: nil, message: 'Template processing failed', details: 'Template name could not be resolved')
  end

  def record_send_result(report, contact, result)
    if result[:ok]
      report.succeeded += 1
      # Store message mapping for async status tracking via webhooks
      create_message_mapping(report, contact, result[:message_id]) if result[:message_id].present?
    else
      report.failed += 1
      error = result[:error] || {}
      report.record_error(code: error[:code], message: error[:message], details: error[:details], fbtrace_id: error[:fbtrace_id])
    end
  end

  def create_message_mapping(report, contact, message_id)
    CampaignMessageMapping.create!(
      campaign_delivery_report: report,
      contact: contact,
      whatsapp_message_id: message_id,
      status: 'sent'
    )
  rescue StandardError => e
    Rails.logger.warn "Failed to create message mapping for campaign #{campaign.id}: #{e.message}"
  end

  def finalize_delivery(report)
    report.finalize!
    Rails.logger.info "Campaign #{campaign.id} delivery completed: #{report.succeeded}/#{report.total} succeeded, #{report.failed} failed"
  end

  def process_liquid_variables(template_params, contact)
    return template_params if template_params.blank?

    personalized = template_params.deep_dup
    if personalized['processed_params'].present?
      liquid_processor = Liquid::TemplateVariableProcessorService.new(drops: liquid_drops(contact))
      personalized['processed_params'] = liquid_processor.process_hash(personalized['processed_params'])
    end
    personalized
  end

  def liquid_drops(contact)
    {
      'contact' => ContactDrop.new(contact),
      'agent' => UserDrop.new(campaign.sender),
      'inbox' => InboxDrop.new(campaign.inbox),
      'account' => AccountDrop.new(campaign.account)
    }
  end
end
