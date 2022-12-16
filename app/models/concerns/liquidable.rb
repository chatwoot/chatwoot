module Liquidable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :labels
    before_create :process_liquid_in_content
  end

  private

  def message_drops
    {
      'contact' => ContactDrop.new(conversation.contact),
      'agent' => UserDrop.new(Current.user),
      'conversation' => ConversationDrop.new(conversation),
      'inbox' => InboxDrop.new(inbox)
    }
  end

  def liquid_processable_message?
    content.present? && message_type == 'outgoing'
  end

  def process_liquid_in_content
    return unless liquid_processable_message?

    template = Liquid::Template.parse(content)
    self.content = template.render(message_drops)
  end
end
