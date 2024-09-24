class Campaign::MultiChannelCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise 'Completed Campaign' if campaign.completed?

    # marks one-off campaign completed so that other jobs won't pick it up

    campaign.completed! if campaign.one_off?
    return unless check_zns_campaign?

    audiences = audience_from_filters
    if audiences.empty?
      audiences = audience_from_labels
    else
      audiences = audiences.merge(audience_from_labels) unless audience_from_labels.empty?
    end
    process_campaign(audiences)
  end

  def process_campaign(audiences)
    audiences.each do |contact|
      next unless scheduled_at_is_today?(contact)

      if campaign.is_zns
        process_zns_message(contact)
      else
        process_channel(contact)
      end
    end
  end

  private

  def check_zns_campaign?
    return true unless campaign.is_zns

    validation = campaign.inbox.channel.validate_zns_template(campaign.zns_template_id, campaign.zns_template_data)
    validation.result
  end

  def audience_from_labels
    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'label' }.pluck('id')
    audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)
    campaign.account.contacts.tagged_with(audience_labels, any: true)
  end

  def audience_from_filters
    all_contacts = Contact.none
    custom_filter_ids = campaign.audience.select { |audience| audience['type'] == 'custom_filter' }.pluck('id')
    custom_filter_ids.each do |custom_filter_id|
      filter = CustomFilter.find(custom_filter_id)
      next if filter.blank?

      action_params = ActionController::Parameters.new(filter.query)
      result = ::Contacts::FilterService.new(action_params.permit!, nil, campaign.account).perform
      contacts = result[:contacts]
      all_contacts = all_contacts.or(contacts)
    end
    all_contacts.distinct
  end

  def process_channel(contact)
    contactable_inboxes = Contacts::ContactableInboxesService.new(contact: contact).get
    return if contactable_inboxes.empty?

    campaign.inboxes.pluck('id').each do |inbox_id|
      contactable_inbox = contactable_inboxes.detect { |item| item[:inbox].id == inbox_id }
      next unless contactable_inbox

      process_message(contact, contactable_inbox)
      break
    end
  end

  def process_zns_message(contact)
    return if contact.phone_number.blank?

    channel = campaign.inbox.channel
    template_data = build_template_data(contact)
    channel.send_message_zns(contact.phone_number, campaign.zns_template_id, template_data, campaign.id)

    cammpaign.update_column(:sent_count, campaign.sent_count + 1) # rubocop:disable Rails/SkipsModelValidations
  end

  def build_template_data(contact)
    template_data = {}
    campaign.zns_template_data.each do |attribute|
      template_data["#{attribute.model}_#{attribute.key}"] = attribute_data(attribute, contact)
    end
    template_data
  end

  def attribute_data(attribute, contact) # rubocop:disable Metrics/CyclomaticComplexity
    case attribute.type
    when 'contact_attribute'
      contact.send(attribute.key)
    when 'contact_custom_attribute'
      contact.custom_attributes[attribute.key]
    when 'product_attribute'
      contact.product&.send(attribute.key)
    when 'product_custom_attribute'
      contact.product&.custom_attributes&.[](attribute.key)
    else
      raise 'Invalid attribute type'
    end
  end

  def process_message(contact, contactable_inbox)
    ActiveRecord::Base.transaction do
      contact_inbox = ContactInboxBuilder.new(
        contact: contact,
        inbox: contactable_inbox[:inbox],
        source_id: contactable_inbox[:source_id]
      ).perform
      conversation = ConversationBuilder.new(
        params: conversation_params(contact),
        contact_inbox: contact_inbox
      ).perform
      if campaign.planned
        Conversations::ConversationPlanBuilder.new(nil, conversation,
                                                   { description: campaign.private_note }).perform
      end
      Messages::MessageBuilder.new(campaign.sender, conversation, message_params).perform

      campaign.update_column(:sent_count, campaign.sent_count + 1) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def conversation_params(contact)
    {
      status: campaign.planned ? :snoozed : :open,
      snoozed_until: campaign.planned ? Time.zone.today + 1 : nil,
      campaign_id: campaign.id,
      assignee_id: contact[:assignee_id],
      team_id: contact[:team_id]
    }
  end

  def message_params
    {
      message_type: campaign.planned ? :activity : :outgoing,
      content: campaign.planned ? campaign.private_note : campaign.message,
      campaign_id: campaign.id
    }
  end

  def scheduled_at_is_today?(contact)
    # one-off campaign has been filtered by scheduled_at from the job
    return true if campaign.one_off?

    # process for flexible scheduled at based on contact data
    scheduled_at = calculate_scheduled_at(contact)
    today = Time.current.beginning_of_day
    scheduled_at&.to_date == today.to_date
  end

  def calculate_scheduled_at(contact)
    flexible_scheduled_at = campaign.flexible_scheduled_at
    extra_days = flexible_scheduled_at['extra_days'].to_i
    calculation = flexible_scheduled_at['calculation']
    attribute_key = flexible_scheduled_at['attribute']['key']
    attribute_type = flexible_scheduled_at['attribute']['type']

    base_date = base_date(contact, attribute_type, attribute_key)

    date_calculation(base_date, calculation, extra_days)
  end

  def base_date(contact, attribute_type, attribute_key) # rubocop:disable Metrics/CyclomaticComplexity
    base_date = case attribute_type
                when 'contact_attribute'
                  contact.send(attribute_key)
                when 'contact_custom_attribute'
                  contact.custom_attributes[attribute_key]
                when 'product_attribute'
                  contact.product&.send(attribute_key)
                when 'product_custom_attribute'
                  contact.product&.custom_attributes&.[](attribute_key)
                else
                  raise 'Invalid attribute type'
                end
    return unless base_date

    # temporarily set timezone at UTC+7 #TODO: need to change to configuration
    timezone = ActiveSupport::TimeZone[7]
    base_date = DateTime.parse(base_date).in_time_zone(timezone) if base_date.is_a?(String)
    base_date
  end

  def date_calculation(base_date, calculation, extra_days)
    return unless base_date

    case calculation
    when 'equal'
      base_date
    when 'plus'
      base_date + extra_days.days
    when 'minus'
      base_date - extra_days.days
    when 'equalWithoutYear'
      Date.new(Time.current.year, base_date.month, base_date.day)
    else
      raise 'Invalid calculation type'
    end
  end
end
