class Api::OneoffApiCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'API' || !campaign.one_off?
    raise 'Completed Campaign' if campaign.completed?

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
    contacts.each_with_index do |contact, index|
      # Apply delay before sending (except for first message)
      if index.positive?
        delay_seconds = campaign.calculate_delay
        if delay_seconds.positive?
          Rails.logger.info "[API Campaign] Applying delay of #{delay_seconds} seconds before sending to contact #{contact.id}"
          sleep(delay_seconds)
        end
      end

      create_conversation_and_message(contact)
    end
  end

  def create_conversation_and_message(contact)
    # Create or find contact inbox for API channel
    contact_inbox = ContactInboxBuilder.new(
      contact: contact,
      inbox: inbox,
      source_id: nil, # Let the builder generate a UUID for API channels
      hmac_verified: false
    ).perform

    return unless contact_inbox

    # Create conversation using the campaign conversation builder
    conversation = Campaigns::CampaignConversationBuilder.new(
      contact_inbox_id: contact_inbox.id,
      campaign_display_id: campaign.display_id,
      conversation_additional_attributes: {},
      custom_attributes: {}
    ).perform

    # The webhook system will handle notifying external systems about new conversations and messages
    Rails.logger.info "[API Campaign] Created conversation #{conversation&.id} for contact #{contact.id} in campaign #{campaign.id}"
  rescue StandardError => e
    Rails.logger.error "[API Campaign] Failed to create conversation for contact #{contact.id}: #{e.message}"
  end
end
