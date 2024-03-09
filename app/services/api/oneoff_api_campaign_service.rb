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

  def process_audience(audience_labels)
    campaign.account.contacts.tagged_with(audience_labels, any: true).each do |contact|
      next if contact.phone_number.blank?

      campaign.inbox.channel.send_message(contact, campaign.message)
    end
  end
end
