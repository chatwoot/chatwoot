class CampaignListener < BaseListener
  def campaign_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    campaign_display_id = event.data[:event_info][:campaign_id]

    return if campaign_display_id.blank?

    ::Campaigns::CampaignConversationBuilder.new(
      contact_inbox: contact_inbox.id,
      campaign_display_id: campaign_display_id,
      conversation_additional_attributes: event.data[:event_info].except(:campaign_id)
    ).perform
  end
end
