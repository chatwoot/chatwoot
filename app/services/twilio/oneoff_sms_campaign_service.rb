class Twilio::OneoffSmsCampaignService
  pattr_initialize [:campaign!]

  def perform
    raise "Invalid campaign #{campaign.id}" if campaign.inbox.inbox_type != 'Twilio SMS' || !campaign.one_off?
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
    campaign.account.contacts.tagged_with(audience_labels, any: true).each do |contact|
      next if contact.phone_number.blank?

      message = campaign.message
      message_drops = {
        'contact' => ContactDrop.new(contact),
        'agent' => UserDrop.new(campaign.sender),
        'inbox' => InboxDrop.new(campaign.inbox),
        'account' => AccountDrop.new(campaign.account)
      }
      content = process_liquid_in_content(message_drops, message)
      channel.send_message(to: contact.phone_number, body: content)
    end
  end

  def process_liquid_in_content(message_drops, message)
    message = message.gsub(/`(.*?)`/m, '{% raw %}`\\1`{% endraw %}')
    template = Liquid::Template.parse(message)
    template.render(message_drops)
  rescue Liquid::Error
    # If there is an error in the liquid syntax, we don't want to process it
  end
end
