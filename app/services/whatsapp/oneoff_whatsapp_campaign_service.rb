class Whatsapp::OneoffWhatsappCampaignService
  pattr_initialize [:campaign!]

  attr_accessor :processed_params

  def perform
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Whatsapp' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

    # marks campaign completed so that other jobs won't pick it up
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')
    audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)
    process_audience(audience_labels)
  end

  private

  delegate :inbox, to: :campaign
  delegate :channel, to: :inbox

  def process_audience(audience_labels)
    campaign.account.contacts.tagged_with(audience_labels, any: true).each do |contact|
      next if contact.phone_number.blank?

      template = fetch_template(campaign.whatsapp_template)
      template_params = template_params(template)
      build_contact_inbox(contact)
      create_conversation(template_content, template_params)
    end
  end

  def fetch_template(template_id)
    whatsapp_channel = find_channel_by_id(campaign.inbox.channel_id)
    return nil if whatsapp_channel.blank?

    whatsapp_channel.message_templates.find { |tmpl| tmpl['id'] == template_id }
  end

  def template_params(template)
    { 'name' => template['name'],
      'namespace' => template['name'],
      'language' => template['language'],
      'category' => template['category'],
      'processed_params' => campaign.template_variables }
  end

  def template_string(template)
    body_component = template['components'].find { |component| component['type'] == 'BODY' }
    body_component ? body_component['text'] : nil
  end

  def process_variable(str)
    str.gsub(/{{|}}/, '')
  end

  def processed_string(template)
    template_str = template_string(template)

    return unless template_str

    template_str.gsub(/{{([^}]+)}}/) do |_match|
      variable = Regexp.last_match(1)
      variable_key = process_variable(variable)
      campaign.template_variables[variable_key] || "{{#{variable}}}"
    end
  end

  def template_content
    template = fetch_template(campaign.whatsapp_template)
    processed_string(template)
  end

  def find_channel_by_id(channel_id)
    Channel::Whatsapp.find(channel_id)
  end

  def create_conversation(message, template_params)
    unless campaign.completed?
      campaign.update!(message: message)
      campaign.completed!
    end

    ::Campaigns::OneoffConversationBuilder.new(
      contact_inbox_id: @contact_inbox.id,
      campaign_display_id: campaign.display_id,
      conversation_additional_attributes: {},
      custom_attributes: {},
      template_params: template_params,
      content: message
    ).perform
  end

  def build_contact_inbox(contact)
    source_id = contact[:phone_number].gsub(/^\+/, '')
    @contact_inbox = ContactInboxBuilder.new(
      contact: contact,
      inbox: campaign.inbox,
      source_id: source_id,
      hmac_verified: ActiveModel::Type::Boolean.new.cast(contact[:hmac_verified]).present?
    ).perform
  end
end
