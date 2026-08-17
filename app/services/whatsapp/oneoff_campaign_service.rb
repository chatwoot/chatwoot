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
    address = campaign_address(contact)
    Rails.logger.info "Processing contact: #{contact.name} (#{address})"

    if address.blank?
      Rails.logger.info "Skipping contact #{contact.name} - no phone number or business scoped user id"
      return
    end

    if campaign.template_params.blank?
      Rails.logger.error "Skipping contact #{contact.name} - no template_params found for WhatsApp campaign"
      return
    end

    processed_template_params = process_liquid_template_params(contact)
    return if processed_template_params.nil?

    send_whatsapp_template_message(to: address, template_params: processed_template_params)
  end

  # A contact that adopted a username can reach a business without ever exposing a phone number,
  # so the only address it has is the business scoped user id stored on its contact inbox. The
  # phone number stays first, which leaves every existing campaign sending exactly what it sends
  # today and changes only the contacts that are skipped as unreachable right now.
  #
  # The identifier scoped to a parent business is the last resort rather than the first choice:
  # it addresses the person relative to the parent, while a campaign goes out from the number
  # behind this inbox. Skipping a contact that carries only that one would reopen the very bug
  # this closes, so it is used when nothing else is available.
  def campaign_address(contact)
    return contact.phone_number if contact.phone_number.present?

    identifiers = campaign_bsuids(contact)
    identifiers.find { |source_id| !RegexHelper::WHATSAPP_BSUID_PARENT_REGEX.match?(source_id) } || identifiers.first
  end

  # Newest first, because the identifier rotates when the person changes phone number and the new
  # row is created after the old one. Without an explicit order the database promises nothing, and
  # a retired identifier does not fail in a way anyone notices: the provider answers 200 and drops
  # the message.
  #
  # Scoped to the campaign's own inbox because the identifier belongs to one business; another
  # number on the same account gives the same person a different one.
  def campaign_bsuids(contact)
    contact.contact_inboxes
           .where(inbox_id: inbox.id)
           .order(id: :desc)
           .pluck(:source_id)
           .select { |source_id| source_id.to_s.match?(RegexHelper::WHATSAPP_BSUID_REGEX) }
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
    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: template_params
    )

    name, namespace, lang_code, processed_parameters = processor.call

    return if name.blank?

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

Whatsapp::OneoffCampaignService.prepend_mod_with('Whatsapp::OneoffCampaignService')
