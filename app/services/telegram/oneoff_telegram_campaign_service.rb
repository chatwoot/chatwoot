class Telegram::OneoffTelegramCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Telegram' || !campaign.one_off?
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
      next if contact[:additional_attributes]['social_telegram_user_id'].blank? ## Chat id validation

      campaign.inbox.channel.send_text_message(contact, campaign.message, campaign.inbox)
    end
  end
end
