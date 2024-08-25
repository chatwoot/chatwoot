class Campaign::MultiChannelCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise 'Completed Campaign' if campaign.completed?

    # marks campaign completed so that other jobs won't pick it up
    campaign.completed!

    audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'label' }.pluck('id')
    audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)
    process_audience(audience_labels)
  end

  private

  def process_audience(audience_labels)
    campaign.account.contacts.tagged_with(audience_labels, any: true).each do |contact|
      process_channel(contact)
    end
  end

  def process_channel(contact)
    contactable_inboxes = Contacts::ContactableInboxesService.new(contact: contact).get

    campaign.inboxes.pluck('id').each do |inbox_id|
      contactable_inbox = contactable_inboxes.detect { |item| item[:inbox].id == inbox_id }
      next unless contactable_inbox

      process_message(contact, contactable_inbox)
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
      Messages::MessageBuilder.new(campaign.sender, conversation, message_params).perform
    end
  end

  def conversation_params(contact)
    additional_attributes = if campaign.planned
                              {
                                created_by: campaign.id,
                                description: campaign.private_note
                              }
                            else
                              {}
                            end

    {
      conversation_type: campaign.planned ? :planned : :default_type,
      status: campaign.planned ? :snoozed : :open,
      snoozed_until: campaign.planned ? campaign.scheduled_at : nil,
      campaign_id: campaign.id,
      assignee_id: contact[:assignee_id],
      team_id: contact[:team_id],
      additional_attributes: ActionController::Parameters.new(additional_attributes).permit!
    }
  end

  def message_params
    {
      message_type: campaign.planned ? :activity : :outgoing,
      content: campaign.planned ? campaign.private_note : campaign.message,
      campaign_id: campaign.id
    }
  end
end
