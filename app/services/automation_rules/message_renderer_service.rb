class AutomationRules::MessageRendererService
  pattr_initialize :conversation, :content

  def perform
    return content if content.blank?

    template = Liquid::Template.parse(content)
    template.render(message_drops)
  rescue Liquid::Error
    # If the user wrote invalid Liquid, fall back to the raw string
    # rather than failing the whole automation.
    content
  end

  private

  def message_drops
    {
      'contact' => ContactDrop.new(conversation.contact),
      'agent' => UserDrop.new(conversation.assignee),
      'conversation' => ConversationDrop.new(conversation),
      'inbox' => InboxDrop.new(conversation.inbox),
      'account' => AccountDrop.new(conversation.account),
      'date' => DateDrop.new
    }
  end
end
