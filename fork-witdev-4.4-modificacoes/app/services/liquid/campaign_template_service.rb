class Liquid::CampaignTemplateService
  pattr_initialize [:campaign!, :contact!]

  def call(message)
    process_liquid_in_content(message_drops, message)
  end

  private

  def message_drops
    {
      'contact' => ContactDrop.new(contact),
      'agent' => UserDrop.new(campaign.sender),
      'inbox' => InboxDrop.new(campaign.inbox),
      'account' => AccountDrop.new(campaign.account)
    }
  end

  def process_liquid_in_content(drops, message)
    message = message.gsub(/`(.*?)`/m, '{% raw %}`\\1`{% endraw %}')
    template = Liquid::Template.parse(message)
    template.render(drops)
  rescue Liquid::Error
    message
  end
end
